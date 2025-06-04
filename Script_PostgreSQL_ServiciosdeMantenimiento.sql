-- Database: ServiciosDeMantenimiento

-- DROP DATABASE IF EXISTS "ServiciosDeMantenimiento";

CREATE DATABASE "ServiciosDeMantenimiento"
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'Spanish_Mexico.1252'
    LC_CTYPE = 'Spanish_Mexico.1252'
    LOCALE_PROVIDER = 'libc'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;

-- Crear esquemas
CREATE SCHEMA Comercial;
CREATE SCHEMA Operativo;

-- CLIENTE
CREATE TABLE Comercial.Cliente (
    idCliente BIGSERIAL PRIMARY KEY,
    RFCCliente VARCHAR(20) NOT NULL,
    nombreCliente VARCHAR(100) NOT NULL,
    telefonoCliente VARCHAR(10) NOT NULL,
    emailCliente VARCHAR(200) NOT NULL
);

-- DOMICILIOCLIENTE
CREATE TABLE Comercial.DomicilioCliente (
    idDomicilio BIGSERIAL PRIMARY KEY,
    idCliente BIGINT NOT NULL,
    domicilioCliente VARCHAR(200) NOT NULL,
    CONSTRAINT FK_CLIENTE01 FOREIGN KEY (idCliente) REFERENCES Comercial.Cliente (idCliente)
);

-- PROVEEDOR
CREATE TABLE Comercial.Proveedor (
    idProveedor BIGSERIAL PRIMARY KEY,
    nombreProveedor VARCHAR(200) NOT NULL,
    telefonoProveedor VARCHAR(10) NOT NULL,
    emailProveedor VARCHAR(200) NOT NULL,
    CONSTRAINT UQ_TELEFONOPROVEEDORUNICO UNIQUE (telefonoProveedor),
    CONSTRAINT UQ_EMAILPROVEEDORUNICO UNIQUE (emailProveedor)
);

-- COMPRA
CREATE TABLE Comercial.Compra (
    idCompra BIGSERIAL PRIMARY KEY,
    idProveedor BIGINT NOT NULL,
    fechaCompra DATE NOT NULL,
    totalCompra NUMERIC,
    CONSTRAINT FK_PROVEEDOR01 FOREIGN KEY (idProveedor) REFERENCES Comercial.Proveedor (idProveedor)
);

-- DETALLECOMPRA
CREATE TABLE Comercial.DetalleCompra (
    idCompra BIGINT NOT NULL,
    idMaterial BIGINT NOT NULL,
    cantidad INT NOT NULL,
    subtotal NUMERIC,
    CONSTRAINT FK_COMPRA FOREIGN KEY (idCompra) REFERENCES Comercial.Compra (idCompra),
    CONSTRAINT FK_MATERIAL FOREIGN KEY (idMaterial) REFERENCES Operativo.Material (idMaterial)
);

-- SERVICIO
CREATE TABLE Operativo.Servicio (
    idServicio BIGSERIAL PRIMARY KEY,
    idDomicilio BIGINT NOT NULL,
    fechaCotizacion DATE NOT NULL,
    fechaInicio DATE NOT NULL,
    fechaFinal DATE NOT NULL,
    duracion INT,
    costoFinal NUMERIC,
    CONSTRAINT FK_DOMICILIO FOREIGN KEY (idDomicilio) REFERENCES Comercial.DomicilioCliente (idDomicilio)
);

-- MATERIAL
CREATE TABLE Operativo.Material (
    idMaterial BIGSERIAL PRIMARY KEY,
    nombreMaterial VARCHAR(100) NOT NULL,
    tipoMaterial VARCHAR(50) NOT NULL,
    precioMaterial NUMERIC NOT NULL,
    existencia INT NOT NULL,
    CONSTRAINT UQ_NOMBREMATERIALUNICO UNIQUE (nombreMaterial)
);

-- MATERIALXSERVICIO
CREATE TABLE Operativo.MaterialXServicio (
    idServicio BIGINT NOT NULL,
    idMaterial BIGINT NOT NULL,
    cantMaterial INT NOT NULL,
    subtotalMaterial NUMERIC,
    CONSTRAINT FK_SERVICIO FOREIGN KEY (idServicio) REFERENCES Operativo.Servicio (idServicio),
    CONSTRAINT FK_MATERIAL2 FOREIGN KEY (idMaterial) REFERENCES Operativo.Material (idMaterial)
);

-- TRABAJADOR
CREATE TABLE Operativo.Trabajador (
    idTrabajador BIGSERIAL PRIMARY KEY,
    RFCTrabajador VARCHAR(13) NOT NULL,
    nombreTrabajador VARCHAR(100) NOT NULL,
    telefonoTrabajador VARCHAR(10) NOT NULL,
    emailTrabajador VARCHAR(200) NOT NULL,
    CONSTRAINT UQ_RFCTRABAJADORUNICO UNIQUE (RFCTrabajador),
    CONSTRAINT UQ_TELEFONOTRABAJADORUNICO UNIQUE (telefonoTrabajador),
    CONSTRAINT UQ_EMAILTRABAJADORUNICO UNIQUE (emailTrabajador)
);

-- DETALLETRABAJADOR
CREATE TABLE Operativo.DetalleTrabajador (
    idTrabajador BIGINT NOT NULL,
    profesion VARCHAR(100) NOT NULL,
    costoBase NUMERIC NOT NULL,
    CONSTRAINT FK_TRABAJADOR FOREIGN KEY (idTrabajador) REFERENCES Operativo.Trabajador (idTrabajador)
);

-- TRABAJADORXSERVICIO
CREATE TABLE Operativo.TrabajadorXServicio (
    idTrabajadorXServicio BIGSERIAL PRIMARY KEY,
    idServicio BIGINT NOT NULL,
    idTrabajador BIGINT NOT NULL,
    subtotalTrabajo NUMERIC(18, 2),
    CONSTRAINT FK_SERVICIO2 FOREIGN KEY (idServicio) REFERENCES Operativo.Servicio (idServicio),
    CONSTRAINT FK_TRABAJADOR2 FOREIGN KEY (idTrabajador) REFERENCES Operativo.Trabajador (idTrabajador)
);

-- REGLAS CON CONSTRAINTS
ALTER TABLE Operativo.Material
ADD CONSTRAINT chk_tipo_material CHECK (tipoMaterial IN ('Plomeria', 'Reconstruccion', 'Electricidad'));

ALTER TABLE Comercial.DetalleCompra
ADD CONSTRAINT chk_cantidad_material CHECK (cantidad >= 1);

-- Disparadores para el proyecto
-- DISPARADOR(ES) PARA DETALLECOMPRA
-- 1. CALCULAR_SUBTOTAL_DETALLECOMPRA
--  ** Al insertar un DetalleCompra, se calculará el subtotal. ** --
CREATE OR REPLACE FUNCTION fn_CalcularSubtotalDetalleCompra()
RETURNS TRIGGER AS $$
DECLARE
    precio DECIMAL;
BEGIN
    -- Obtener el precio del material desde la tabla Operativo.Material
    SELECT precioMaterial 
    INTO precio
    FROM Operativo.Material
    WHERE idMaterial = NEW.idMaterial;

    -- Calcular el subtotal
    NEW.subtotal := NEW.cantidad * precio;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TGR_CALCULAR_SUBTOTAL_DETALLECOMPRA
BEFORE INSERT OR UPDATE ON Comercial.DetalleCompra
FOR EACH ROW EXECUTE FUNCTION fn_CalcularSubtotalDetalleCompra();

-- 2. TGR_ACTUALIZATOTALCOMPRA
-- ** Al insertar un DetalleCompra, se calculará el totalCompra de la Compra. ** --
CREATE OR REPLACE FUNCTION fn_ActualizarTotalCompra()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE Comercial.Compra
    SET totalCompra = ROUND((
        SELECT COALESCE(SUM(subtotal), 0::numeric) 
        FROM Comercial.DetalleCompra 
        WHERE idCompra = COALESCE(NEW.idCompra, OLD.idCompra)
    ), 2) -- Redondea a 2 decimales
    WHERE idCompra = COALESCE(NEW.idCompra, OLD.idCompra);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER TGR_ACTUALIZATOTALCOMPRA
AFTER INSERT OR UPDATE OR DELETE ON Comercial.DetalleCompra
FOR EACH ROW EXECUTE FUNCTION fn_ActualizarTotalCompra();

-- 3. TGR_ACTUALIZA_MATERIAL
-- ** Actualiza la existencia en Material al momento de insertar un DetalleCompra. ** --
CREATE OR REPLACE FUNCTION fn_ActualizarExistenciasMaterialenDC()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE Operativo.Material
        SET existencia = existencia + NEW.cantidad
        WHERE idMaterial = NEW.idMaterial;
    ELSIF TG_OP = 'UPDATE' THEN
        UPDATE Operativo.Material
        SET existencia = existencia - OLD.cantidad + NEW.cantidad
        WHERE idMaterial = NEW.idMaterial;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE Operativo.Material
        SET existencia = existencia - OLD.cantidad
        WHERE idMaterial = OLD.idMaterial;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TGR_ACTUALIZA_MATERIAL
AFTER INSERT OR UPDATE OR DELETE ON Comercial.DetalleCompra
FOR EACH ROW EXECUTE FUNCTION fn_ActualizarExistenciasMaterialenDC();

--DISPARADOR(ES) PARA SERVICIO
-- 4. TGR_UPDATE_COSTO_FINAL
-- ** Al insertar un MaterialXServicio actualiza el costoFinal del Servicio. ** --
CREATE OR REPLACE FUNCTION fn_UpdateCostoFinalServicio()
RETURNS TRIGGER AS $$
DECLARE
    subtotalMaterialF DECIMAL;
    subtotalTrabajoF DECIMAL;
BEGIN
    -- Calculamos el subtotal de materiales
    SELECT COALESCE(SUM(subtotalMaterial), 0)
    INTO subtotalMaterialF
    FROM Operativo.MaterialXServicio
    WHERE idServicio = NEW.idServicio;

    -- Calculamos el subtotal de trabajo
    SELECT COALESCE(SUM(subtotalTrabajo), 0)
    INTO subtotalTrabajoF
    FROM Operativo.TrabajadorXServicio
    WHERE idServicio = NEW.idServicio;

    -- Actualizamos el costoFinal solo si hay cambios
    UPDATE Operativo.Servicio
    SET costoFinal = ROUND(subtotalMaterialF + subtotalTrabajoF, 2)
    WHERE idServicio = NEW.idServicio;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TGR_UPDATE_COSTO_FINAL_MATERIAL
AFTER INSERT OR UPDATE OR DELETE ON Operativo.MaterialXServicio
FOR EACH ROW EXECUTE FUNCTION fn_UpdateCostoFinalServicio();

CREATE TRIGGER TGR_UPDATE_COSTO_FINAL_TRABAJADOR
AFTER INSERT OR UPDATE OR DELETE ON Operativo.TrabajadorXServicio
FOR EACH ROW EXECUTE FUNCTION fn_UpdateCostoFinalServicio();

-- 5. TGR_DURACIONSERVICIO
-- ** Al insertar un Servicio se actualizará la duracion, en base a sus fechas. ** --
CREATE OR REPLACE FUNCTION fn_calcularduracionservicio() 
RETURNS TRIGGER AS $$
BEGIN
    -- Verificar que los campos fechaInicio y fechaFinal existen
    IF NEW.fechaInicio IS NOT NULL AND NEW.fechaFinal IS NOT NULL THEN
        -- Calcular la duración en días entre las dos fechas
        NEW.duracion := 1 + (NEW.fechaFinal - NEW.fechaInicio); -- La duración es un valor en días
    ELSE
        -- Si alguna de las fechas es nula, asignar duración nula
        NEW.duracion := NULL;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TGR_DURACIONSERVICIO
BEFORE INSERT OR UPDATE ON Operativo.Servicio
FOR EACH ROW EXECUTE FUNCTION fn_CalcularDuracionServicio();

--DISPARADOR(ES) PARA MATERIAL
-- 6. TGR_CALCULA_SUBTOTAL_MATERIAL
-- ** Calcula el subtotalMaterial de un MaterialXServicio. ** --
CREATE OR REPLACE FUNCTION fn_CalculaSubtotalMaterial()
RETURNS TRIGGER AS $$
BEGIN
    NEW.subtotalMaterial := ROUND(
        NEW.cantMaterial * 
        (SELECT precioMaterial FROM Operativo.Material WHERE idMaterial = NEW.idMaterial), 
        2 -- Redondear a 2 decimales
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TGR_CALCULA_SUBTOTAL_MATERIAL
BEFORE INSERT OR UPDATE ON Operativo.MaterialXServicio
FOR EACH ROW EXECUTE FUNCTION fn_CalculaSubtotalMaterial();

-- 7. TRG_UPDATECOSTOFINAL_MATERIALXSERVICIO
-- ** Al insertar un MaterialXServicio actualiza el costoFinal. ** --
CREATE OR REPLACE FUNCTION fn_UpdateCostoFinalMaterialXServicio()
RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT costoFinal FROM Operativo.Servicio WHERE idServicio = NEW.idServicio) IS NULL THEN
        UPDATE Operativo.Servicio
        SET costoFinal = ROUND(
                            (SELECT COALESCE(SUM(subtotalMaterial), 0::numeric) 
                             FROM Operativo.MaterialXServicio 
                             WHERE idServicio = NEW.idServicio), 2) -- Redondear a 2 decimales
        WHERE idServicio = NEW.idServicio;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TRG_UPDATECOSTOFINAL_MATERIALXSERVICIO
AFTER INSERT OR UPDATE ON Operativo.MaterialXServicio
FOR EACH ROW EXECUTE FUNCTION fn_UpdateCostoFinalMaterialXServicio();

-- 8. TGR_ACTUALIZAR_EXISTENCIAS_MATERIAL
-- ** Al insertar un MaterialXServicio se actualizará la existencia del Material. ** --
CREATE OR REPLACE FUNCTION fn_ActualizarExistenciasMaterial()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE Operativo.Material
        SET existencia = existencia - NEW.cantMaterial
        WHERE idMaterial = NEW.idMaterial;
ELSIF TG_OP = 'UPDATE' THEN
        UPDATE Operativo.Material
        SET existencia = existencia + OLD.cantMaterial - NEW.cantMaterial
        WHERE idMaterial = NEW.idMaterial;
ELSIF TG_OP = 'DELETE' THEN
        UPDATE Operativo.Material
        SET existencia = existencia + OLD.cantMaterial
        WHERE idMaterial = OLD.idMaterial;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TGR_ACTUALIZAR_EXISTENCIAS_MATERIAL
AFTER INSERT OR UPDATE OR DELETE ON Operativo.MaterialXServicio
FOR EACH ROW EXECUTE FUNCTION fn_ActualizarExistenciasMaterial();

--DISPARADOR(ES) PARA TRABAJADOR
-- 9. TGR_CALCULASUBTOTALTRABAJO
-- ** Al insertar un TrabajoXServicio se aumentará el 15% del costoBase al subtotalTrabajo. ** --
CREATE OR REPLACE FUNCTION fn_CalculaSubtotalTrabajo()
RETURNS TRIGGER AS $$
DECLARE
    totalCostoBase NUMERIC; -- Variable temporal para almacenar la suma de costoBase
BEGIN
    -- Calcular la suma de costoBase para el idTrabajador asociado
    SELECT SUM(costoBase)
    INTO totalCostoBase
    FROM Operativo.DetalleTrabajador
    WHERE idTrabajador = NEW.idTrabajador;

    -- Si no hay registros asociados, asignar subtotalTrabajo como 0
    IF totalCostoBase IS NULL THEN
        totalCostoBase := 0;
    END IF;

    -- Multiplicar por 1.15 y asignar a subtotalTrabajo
    NEW.subtotalTrabajo := totalCostoBase * 1.15;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TGR_CALCULASUBTOTALTRABAJO
BEFORE INSERT OR UPDATE ON Operativo.TrabajadorXServicio
FOR EACH ROW EXECUTE FUNCTION fn_CalculaSubtotalTrabajo();

-- 10. TRG_UPDATECOSTOFINAL_TRABAJADORXSERVICIO
-- ** El costoFinal de un Servicio se actualizará al insertar un TrabajadorXServicio. ** --
CREATE OR REPLACE FUNCTION fn_UpdateCostoFinalTrabajadorXServicio()
RETURNS TRIGGER AS $$
BEGIN
    -- Actualizar el costoFinal después de un INSERT o UPDATE
    IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
        UPDATE Operativo.Servicio
        SET costoFinal = (SELECT COALESCE(SUM(subtotalTrabajo), 0) FROM Operativo.TrabajadorXServicio WHERE idServicio = NEW.idServicio)
        WHERE idServicio = NEW.idServicio;

    -- Actualizar el costoFinal después de un DELETE
    ELSIF (TG_OP = 'DELETE') THEN
        UPDATE Operativo.Servicio
        SET costoFinal = (SELECT COALESCE(SUM(subtotalTrabajo), 0) FROM Operativo.TrabajadorXServicio WHERE idServicio = OLD.idServicio)
        WHERE idServicio = OLD.idServicio;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TRG_UPDATECOSTOFINAL_TRABAJADORXSERVICIO
AFTER INSERT OR UPDATE OR DELETE ON Operativo.TrabajadorXServicio
FOR EACH ROW EXECUTE FUNCTION fn_UpdateCostoFinalTrabajadorXServicio();

--USUARIOS 
--USUARIO ADMINISTRADOR 
CREATE USER admin WITH PASSWORD 'AdminPostgres';
GRANT ALL PRIVILEGES ON DATABASE "ServiciosDeMantenimiento" TO admin;

--USUARIO GERENTE
CREATE USER gerente WITH PASSWORD 'GerentePostgres';
GRANT CONNECT ON DATABASE "ServiciosDeMantenimiento" TO gerente;
GRANT USAGE ON SCHEMA Comercial, Operativo TO gerente;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE Comercial.Cliente TO gerente;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE Comercial.Proveedor TO gerente;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE Comercial.Compra TO gerente;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE Operativo.Trabajador TO gerente;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE Operativo.Material TO gerente;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE Operativo.Servicio TO gerente;

--USUARIO EMPLEADO
CREATE USER empleado WITH PASSWORD 'EmpleadoPostgres';
GRANT CONNECT ON DATABASE "ServiciosDeMantenimiento" TO empleado;
GRANT USAGE ON SCHEMA Comercial, Operativo TO empleado;
GRANT SELECT ON TABLE Comercial.Cliente TO gerente;
GRANT SELECT ON TABLE Comercial.Proveedor TO gerente;
GRANT SELECT ON TABLE Comercial.Compra TO gerente;
GRANT SELECT ON TABLE Operativo.Trabajador TO gerente;
GRANT SELECT ON TABLE Operativo.Material TO gerente;
GRANT SELECT ON TABLE Operativo.Servicio TO gerente;
REVOKE INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA Comercial, Operativo FROM empleado;

