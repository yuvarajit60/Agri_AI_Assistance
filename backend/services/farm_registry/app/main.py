from __future__ import annotations

import uuid

from fastapi import Depends, FastAPI, HTTPException
from sqlalchemy.orm import Session

from . import models
from .db import Base, engine, get_db
from .resolution import DEFAULT_RESOLUTION_CONFIDENCE
from .schemas import FarmCreate, FarmOut, FarmUpdate, GeoJSONPolygon, SoilReport, UserCreate, UserOut, UserUpdate

app = FastAPI(title="Farm Registry Service", version="0.2.0")


@app.on_event("startup")
def on_startup() -> None:
    Base.metadata.create_all(bind=engine)


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/users", response_model=UserOut, status_code=201)
def create_or_get_user(payload: UserCreate, db: Session = Depends(get_db)) -> models.User:
    existing = db.query(models.User).filter(models.User.phone_number == payload.phone_number).one_or_none()
    if existing:
        return existing
    user = models.User(phone_number=payload.phone_number)
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


@app.patch("/users/{user_id}", response_model=UserOut)
def update_user(user_id: uuid.UUID, payload: UserUpdate, db: Session = Depends(get_db)) -> models.User:
    user = db.get(models.User, user_id)
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(user, field, value)
    db.commit()
    db.refresh(user)
    return user


@app.get("/users/{user_id}", response_model=UserOut)
def get_user(user_id: uuid.UUID, db: Session = Depends(get_db)) -> models.User:
    user = db.get(models.User, user_id)
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")
    return user


def _farm_to_out(farm: models.Farm) -> FarmOut:
    return FarmOut(
        id=farm.id,
        owner_id=farm.owner_id,
        name=farm.name,
        resolution_method=farm.resolution_method,
        resolution_confidence=farm.resolution_confidence,
        centroid_lat=farm.centroid_lat,
        centroid_lon=farm.centroid_lon,
        area_acres=farm.area_acres,
        boundary=GeoJSONPolygon(**farm.boundary_geojson) if farm.boundary_geojson else None,
        soil_report=SoilReport(**farm.soil_report) if farm.soil_report else None,
        created_at=farm.created_at,
    )


@app.post("/farms", response_model=FarmOut, status_code=201)
def create_farm(payload: FarmCreate, db: Session = Depends(get_db)) -> FarmOut:
    owner = db.get(models.User, payload.owner_id)
    if owner is None:
        raise HTTPException(status_code=404, detail="Owner user not found")

    farm = models.Farm(
        owner_id=payload.owner_id,
        name=payload.name,
        boundary_geojson=payload.boundary.model_dump() if payload.boundary is not None else None,
        centroid_lat=payload.centroid_lat,
        centroid_lon=payload.centroid_lon,
        area_acres=payload.area_acres,
        soil_report=payload.soil_report.model_dump() if payload.soil_report is not None else None,
        resolution_method=payload.resolution_method,
        resolution_confidence=DEFAULT_RESOLUTION_CONFIDENCE[payload.resolution_method],
    )
    db.add(farm)
    db.commit()
    db.refresh(farm)
    return _farm_to_out(farm)


@app.get("/farms/{farm_id}", response_model=FarmOut)
def get_farm(farm_id: uuid.UUID, db: Session = Depends(get_db)) -> FarmOut:
    farm = db.get(models.Farm, farm_id)
    if farm is None:
        raise HTTPException(status_code=404, detail="Farm not found")
    return _farm_to_out(farm)


@app.patch("/farms/{farm_id}", response_model=FarmOut)
def update_farm(farm_id: uuid.UUID, payload: FarmUpdate, db: Session = Depends(get_db)) -> FarmOut:
    farm = db.get(models.Farm, farm_id)
    if farm is None:
        raise HTTPException(status_code=404, detail="Farm not found")

    if payload.name is not None:
        farm.name = payload.name
    if payload.area_acres is not None:
        farm.area_acres = payload.area_acres
    if payload.clear_soil_report:
        farm.soil_report = None
    elif payload.soil_report is not None:
        farm.soil_report = payload.soil_report.model_dump()

    db.commit()
    db.refresh(farm)
    return _farm_to_out(farm)


@app.delete("/farms/{farm_id}", status_code=204)
def delete_farm(farm_id: uuid.UUID, db: Session = Depends(get_db)) -> None:
    farm = db.get(models.Farm, farm_id)
    if farm is None:
        raise HTTPException(status_code=404, detail="Farm not found")
    db.delete(farm)
    db.commit()


@app.get("/users/{user_id}/farms", response_model=list[FarmOut])
def list_user_farms(user_id: uuid.UUID, db: Session = Depends(get_db)) -> list[FarmOut]:
    farms = db.query(models.Farm).filter(models.Farm.owner_id == user_id).all()
    return [_farm_to_out(f) for f in farms]
