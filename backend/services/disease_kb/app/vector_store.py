"""BGE-M3 embeddings + a local (embedded, file-based) Qdrant collection —
recommended combination from docs/architecture (multilingual retrieval
quality for Tamil/English, and a vector DB that starts as zero-infra local
storage but is the same client API against a real Qdrant server later).

Indexing happens once at startup (~12 documents — sub-second after the
model is loaded); this is not a hot path.
"""

from __future__ import annotations

import logging
from pathlib import Path

from qdrant_client import QdrantClient
from qdrant_client.models import Distance, PointStruct, VectorParams
from sentence_transformers import SentenceTransformer

from .knowledge_base import embedding_text, load_knowledge_base

logger = logging.getLogger(__name__)

_COLLECTION = "organic_disease_guidance"
_EMBED_DIM = 1024  # BAAI/bge-m3 dense embedding size
_STORAGE_PATH = Path(__file__).parent / "qdrant_storage"

_model: SentenceTransformer | None = None
_client: QdrantClient | None = None


def _get_model() -> SentenceTransformer:
    global _model
    if _model is None:
        logger.info("Loading BAAI/bge-m3 embedding model (first call — may take a while to download)...")
        _model = SentenceTransformer("BAAI/bge-m3")
    return _model


def _get_client() -> QdrantClient:
    global _client
    if _client is None:
        _client = QdrantClient(path=str(_STORAGE_PATH))
    return _client


def ensure_indexed() -> int:
    """Idempotent: (re)builds the collection from the current knowledge
    base JSON. Returns the number of documents indexed."""
    client = _get_client()
    model = _get_model()
    entries = load_knowledge_base()

    client.recreate_collection(
        collection_name=_COLLECTION,
        vectors_config=VectorParams(size=_EMBED_DIM, distance=Distance.COSINE),
    )

    texts = [embedding_text(e) for e in entries]
    vectors = model.encode(texts, normalize_embeddings=True, show_progress_bar=False)

    points = [
        PointStruct(id=i, vector=vectors[i].tolist(), payload=entries[i])
        for i in range(len(entries))
    ]
    client.upsert(collection_name=_COLLECTION, points=points)
    logger.info("Indexed %d organic disease guidance documents into Qdrant.", len(entries))
    return len(entries)


def search(query: str, top_k: int = 3, crop: str | None = None) -> list[dict]:
    client = _get_client()
    model = _get_model()
    query_vector = model.encode([query], normalize_embeddings=True)[0].tolist()

    # Crop names in the knowledge base are free-text ("Vegetables (Tomato)",
    # "Potato") rather than a controlled vocabulary, so an exact Qdrant-level
    # filter (crop="tomato") would reject every real match. Over-fetch and
    # filter case-insensitively/substring-wise in Python instead — the
    # knowledge base is small enough (~12 docs) that this costs nothing.
    fetch_limit = 50 if crop else top_k
    results = client.query_points(
        collection_name=_COLLECTION,
        query=query_vector,
        limit=fetch_limit,
    ).points

    matches = [{"score": r.score, **r.payload} for r in results]
    if crop:
        needle = crop.strip().lower()
        matches = [m for m in matches if any(needle in c.lower() for c in m.get("crops", []))]
    return matches[:top_k]
