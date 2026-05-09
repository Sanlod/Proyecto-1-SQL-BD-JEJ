ALTER TABLE CRIBHOUSE DROP COLUMN acceptedPetType; --varcahr2(200)
ALTER TABLE CRIBHOUSE DROP COLUMN acceptedEnergyLevel; --varcahr2(200)

DROP TABLE cribHouseXPetType;
-- No estaba seguro entonces mejor de nuevo 

CREATE TABLE cribHouseXPetType (
    idCribhouse NUMBER,
    idPetType NUMBER,
    CONSTRAINT pk_ch_pet PRIMARY KEY (idCribhouse, idPetType),
    CONSTRAINT fk_ch_id FOREIGN KEY (idCribhouse) REFERENCES cribHouse(id),
    CONSTRAINT fk_pet_id FOREIGN KEY (idPetType) REFERENCES PetType(id)
);
ALTER TABLE CRIBHOUSE ADD acceptedPetSize VARCHAR2(200) NOT NULL;

CREATE TABLE cribHouseXEnergyLevel(
    idCribhouse NUMBER,
    idEnergyLevel NUMBER,
    CONSTRAINT pk_ch_el PRIMARY KEY (idCribhouse, idEnergyLevel),
    CONSTRAINT fk_crib FOREIGN KEY (idCribhouse) REFERENCES cribHouse(id),
    CONSTRAINT fk_ener FOREIGN KEY (idEnergyLevel) REFERENCES EnergyLevel(id)
);