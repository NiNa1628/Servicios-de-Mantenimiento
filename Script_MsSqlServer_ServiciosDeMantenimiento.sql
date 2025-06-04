USE ServiciosdeMantenimiento

--Esquemas con los que se trabajó el proyecto
CREATE SCHEMA Comercial
--para gestionar clientes, proveedores, compras y domicilios.
CREATE SCHEMA Operativo
--para gestionar servicios, trabajadores, materiales y las relaciones entre ellos.

--Tablas para el proyecto
--CLIENTE
CREATE TABLE Comercial.Cliente
(
	idCliente BIGINT IDENTITY(1,1) NOT NULL,
	RFCCliente VARCHAR(20) NOT NULL,
	nombreCliente VARCHAR(100) NOT NULL,
	telefonoCliente VARCHAR(10) NOT NULL,
	emailCliente VARCHAR(200) NOT NULL,

	CONSTRAINT PK_CLIENTE PRIMARY KEY (idCliente)
)

--DOMICILIOCLIENTE
CREATE TABLE Comercial.DomicilioCliente
(
	idDomicilio BIGINT IDENTITY(1,1) NOT NULL,
	idCliente BIGINT NOT NULL,
	domicilioCliente VARCHAR(200) NOT NULL,

	CONSTRAINT PK_DOMICILIO PRIMARY KEY (idDomicilio),
	CONSTRAINT FK_CLIENTE01 FOREIGN KEY(idCliente)
	REFERENCES Comercial.Cliente(idCliente)
)

--PROVEEDOR
CREATE TABLE Comercial.Proveedor
(
	idProveedor BIGINT IDENTITY(1,1) NOT NULL,
	nombreProveedor VARCHAR(200) NOT NULL,
	telefonoProveedor VARCHAR(10) NOT NULL,
	emailProveedor VARCHAR(200) NOT NULL,

	CONSTRAINT PK_PROVEEDOR PRIMARY KEY (idProveedor)
)
ALTER TABLE Comercial.Proveedor ADD CONSTRAINT UQ_TELEFONOPROVEEDORUNICO UNIQUE (telefonoProveedor);
ALTER TABLE Comercial.Proveedor ADD CONSTRAINT UQ_EMAILPROVEEDORUNICO UNIQUE (emailProveedor);

-- COMPRA
CREATE TABLE Comercial.Compra
(
	idCompra BIGINT IDENTITY(1,1) NOT NULL,
	idProveedor BIGINT NOT NULL,
	fechaCompra DATE NOT NULL,
	totalCompra MONEY,

	CONSTRAINT PK_COMPRA PRIMARY KEY (idCompra),
	CONSTRAINT FK_PROVEEDOR01 FOREIGN KEY(idProveedor)
	REFERENCES Comercial.Proveedor(idProveedor)
)
ALTER TABLE Comercial.Compra
ALTER COLUMN totalCompra DECIMAL(18, 2) NULL;

CREATE TABLE Comercial.DetalleCompra
(
	idCompra BIGINT NOT NULL,
	idMaterial BIGINT NOT NULL,
	cantidad INT NOT NULL,
	subtotal MONEY,

	CONSTRAINT FK_COMPRA FOREIGN KEY(idCompra)
	REFERENCES Comercial.Compra(idCompra),
	CONSTRAINT FK_MATERIAL FOREIGN KEY(idMaterial)
	REFERENCES Operativo.Material(idMaterial)
)
ALTER TABLE Comercial.DetalleCompra
ALTER COLUMN subtotal DECIMAL(18, 2) NULL;

--SERVICIO
CREATE TABLE Operativo.Servicio
(
	idServicio BIGINT IDENTITY(1,1) NOT NULL,
	idDomicilio BIGINT NOT NULL,
	fechaCotizacion DATE NOT NULL,
	fechaInicio DATE NOT NULL,
	fechaFinal DATE NOT NULL,
	duracion INT,
	costoFinal DECIMAL,

	CONSTRAINT PK_SERVICIO PRIMARY KEY (idServicio),
	CONSTRAINT FK_DOMICILIO FOREIGN KEY (idDomicilio)
	REFERENCES Comercial.DomicilioCliente (idDomicilio)
)

--MATERIAL
CREATE TABLE Operativo.Material
(
	idMaterial BIGINT IDENTITY(1,1) NOT NULL,
	nombreMaterial VARCHAR(100) NOT NULL,
	tipoMaterial VARCHAR(50) NOT NULL,
	precioMaterial MONEY NOT NULL,
	existencia INT NOT NULL,

	CONSTRAINT FK_MATERIAL PRIMARY KEY (idMaterial)
)
ALTER TABLE Operativo.Material ADD CONSTRAINT UQ_NOMBREMATERIALUNICO UNIQUE (nombreMaterial);

CREATE TABLE Operativo.MaterialXServicio
(
	idServicio BIGINT NOT NULL,
	idMaterial BIGINT NOT NULL,
	cantMaterial INT NOT NULL,
	subtotalMaterial DECIMAL,

	CONSTRAINT FK_SERVICIO FOREIGN KEY (idServicio)
	REFERENCES Operativo.Servicio (idServicio),
	CONSTRAINT FK_MATERIAL2 FOREIGN KEY (idMaterial)
	REFERENCES Operativo.Material (idMaterial)
)

--TRABAJADOR
CREATE TABLE Operativo.Trabajador 
(
	idTrabajador BIGINT IDENTITY (1,1) NOT NULL,
	RFCTrabajador VARCHAR(13) NOT NULL,
	nombreTrabajador VARCHAR(100) NOT NULL,
	telefonoTrabajador VARCHAR(10) NOT NULL,
	emailTrabajador VARCHAR(200) NOT NULL

	CONSTRAINT PK_TRABAJADOR PRIMARY KEY (idTrabajador)
)
ALTER TABLE Operativo.Trabajador ADD CONSTRAINT UQ_RFCTRABAJADORUNICO UNIQUE (RFCTrabajador);
ALTER TABLE Operativo.Trabajador ADD CONSTRAINT UQ_TELEFONOTRABAJADORUNICO UNIQUE (telefonoTrabajador);
ALTER TABLE Operativo.Trabajador ADD CONSTRAINT UQ_EMAILTRABAJADORUNICO UNIQUE (emailTrabajador);

CREATE TABLE Operativo.DetalleTrabajador 
(
	idTrabajador BIGINT NOT NULL,
	profesion VARCHAR(100) NOT NULL,
	costoBase  MONEY NOT NULL

	CONSTRAINT FK_TRABAJADOR FOREIGN KEY (idTrabajador) 
	REFERENCES Operativo.Trabajador(idTrabajador)
)

CREATE TABLE Operativo.TrabajadorXServicio
(
	idTrabajadorXServicio BIGINT IDENTITY (1,1) NOT NULL,
	idServicio  BIGINT NOT NULL,
	idTrabajador BIGINT NOT NULL,
	subtotalTrabajo  MONEY

	CONSTRAINT PK_TRABAJADORXSERVICIO PRIMARY KEY (idTrabajadorXServicio),
	CONSTRAINT FK_SERVICIO2 FOREIGN KEY (idServicio) 
	REFERENCES Operativo.Servicio(idServicio), 
	CONSTRAINT FK_TRABAJADOR2  FOREIGN KEY (idTrabajador) 
	REFERENCES Operativo.Trabajador(idTrabajador)
)

--REGLAS	
CREATE RULE RL_TIPO_MATERIAL AS @TIPO IN ('Plomeria', 'Reconstruccion', 'Electricidad')
EXEC sp_bindrule 'RL_TIPO_MATERIAL', 'Operativo.Material.tipoMaterial'

CREATE RULE RL_CANT_MATERIAL AS @CANTIDAD >= 1
EXEC sp_bindrule 'RL_CANT_MATERIAL','Comercial.DetalleCompra.cantidad'

--Disparadores para el proyecto
--DISPARADOR(ES) PARA DETALLECOMPRA
-- 1. CALCULAR_SUBTOTAL_DETALLECOMPRA
--  ** Al insertar un DetalleCompra, se calculará el subtotal. ** --
CREATE TRIGGER TGR_CALCULAR_SUBTOTAL_DETALLECOMPRA
ON Comercial.DetalleCompra
AFTER INSERT, UPDATE
AS
BEGIN
    DECLARE @idCompra BIGINT;
    DECLARE @idMaterial BIGINT;
    DECLARE @cantidad INT;
    DECLARE @precioMaterial MONEY;
    DECLARE @subtotal DECIMAL(18, 2);

    -- Obtener los valores insertados o actualizados
    SELECT @idCompra = idCompra, @idMaterial = idMaterial, @cantidad = cantidad
    FROM inserted;

    -- Obtener el precio del material
    SELECT @precioMaterial = precioMaterial
    FROM Operativo.Material
    WHERE idMaterial = @idMaterial;

    -- Calcular el subtotal
    SET @subtotal = @precioMaterial * @cantidad;

    -- Actualizar el campo subtotal en la tabla DetalleCompra
    UPDATE Comercial.DetalleCompra
    SET subtotal = @subtotal
    WHERE idCompra = @idCompra AND idMaterial = @idMaterial;
END;

-- 2. TGR_ACTUALIZATOTALCOMPRA
-- ** Al insertar un DetalleCompra, se calculará el totalCompra de la Compra. ** --
CREATE TRIGGER TGR_ACTUALIZATOTALCOMPRA
ON Comercial.DetalleCompra
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    -- Declarar variables
    DECLARE @idCompra INT;
    
    -- Calcular el nuevo total de la compra sumando todos los subtotales de los DetalleCompra asociados
    DECLARE @nuevoTotal DECIMAL(18, 2);
    
    -- Verificar si es una inserción o actualización
    IF EXISTS (SELECT 1 FROM inserted)
    BEGIN
        -- Obtener el idCompra de los registros insertados o actualizados
        SELECT @idCompra = (SELECT TOP 1 idCompra FROM inserted);
        
        -- Calcular el nuevo total
        SELECT @nuevoTotal = ISNULL(SUM(subtotal), 0)
        FROM Comercial.DetalleCompra
        WHERE idCompra = @idCompra;
        
        -- Actualizar el totalCompra en la tabla Comercial.Compra
        UPDATE Comercial.Compra
        SET totalCompra = @nuevoTotal
        WHERE idCompra = @idCompra;
    END
    
    -- Verificar si es una eliminación
    IF EXISTS (SELECT 1 FROM deleted)
    BEGIN
        -- Obtener el idCompra de los registros eliminados
        SELECT @idCompra = (SELECT TOP 1 idCompra FROM deleted);
        
        -- Calcular el nuevo total
        SELECT @nuevoTotal = ISNULL(SUM(subtotal), 0)
        FROM Comercial.DetalleCompra
        WHERE idCompra = @idCompra;
        
        -- Actualizar el totalCompra en la tabla Comercial.Compra
        UPDATE Comercial.Compra
        SET totalCompra = @nuevoTotal
        WHERE idCompra = @idCompra;
    END
END;

-- 3. TGR_ACTUALIZA_MATERIAL
-- ** Actualiza la existencia en Material al momento de insertar un DetalleCompra. ** --
CREATE TRIGGER TGR_ACTUALIZA_MATERIAL
ON Comercial.DetalleCompra
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    -- Manejo de inserciones
    IF EXISTS (SELECT * FROM inserted) AND NOT EXISTS (SELECT * FROM deleted)
    BEGIN
        -- Actualizar la existencia sumando las nuevas cantidades
        UPDATE Operativo.Material
        SET existencia = existencia + i.cantidad
        FROM inserted i
        WHERE Operativo.Material.idMaterial = i.idMaterial;
    END

    -- Manejo de actualizaciones
    IF EXISTS (SELECT * FROM deleted) AND EXISTS (SELECT * FROM deleted)
    BEGIN
        -- Actualizar la existencia restando las antiguas cantidades
        UPDATE Operativo.Material
        SET existencia = existencia - d.cantidad + i.cantidad
        FROM deleted d
        JOIN inserted i ON d.idMaterial = i.idMaterial
        WHERE Operativo.Material.idMaterial = d.idMaterial;
    END

    -- Manejo de eliminaciones
    IF EXISTS (SELECT * FROM deleted) AND NOT EXISTS (SELECT * FROM inserted)
    BEGIN
        -- Restar las cantidades al eliminar registros de DetalleCompra
        UPDATE Operativo.Material
        SET existencia = existencia - d.cantidad
        FROM deleted d
        WHERE Operativo.Material.idMaterial = d.idMaterial;
    END
END;

--DISPARADOR(ES) PARA SERVICIO
-- 4. TGR_UPDATE_COSTO_FINAL
-- ** Suma los subtotalTrabajo y subtotalMaterial para actualizar el costoFinal del Servicio. ** --
CREATE TRIGGER TGR_UPDATE_COSTO_FINAL
ON Operativo.Servicio
AFTER INSERT, UPDATE
AS
BEGIN
    -- Evita la recursión verificando el nivel de anidación
    IF (TRIGGER_NESTLEVEL() > 1) RETURN;

    DECLARE @idServicio BIGINT;
    DECLARE @subtotalMaterial DECIMAL(18, 2) = 0;
    DECLARE @subtotalTrabajo DECIMAL(18, 2) = 0;
    DECLARE @nuevoCostoFinal DECIMAL(18, 2);
    DECLARE @costoActual DECIMAL(18, 2);

    -- Obtener el idServicio del registro afectado
    SELECT @idServicio = idServicio FROM inserted;

    -- Calcular los subtotales
    SELECT @subtotalMaterial = ISNULL(SUM(subtotalMaterial), 0)
    FROM Operativo.MaterialXServicio
    WHERE idServicio = @idServicio;

    SELECT @subtotalTrabajo = ISNULL(SUM(subtotalTrabajo), 0)
    FROM Operativo.TrabajadorXServicio
    WHERE idServicio = @idServicio;

    -- Calcular el nuevo costo final
    SET @nuevoCostoFinal = @subtotalMaterial + @subtotalTrabajo;

    -- Obtener el costo actual
    SELECT @costoActual = costoFinal
    FROM Operativo.Servicio
    WHERE idServicio = @idServicio;

    -- Actualizar solo si el costo ha cambiado
    IF (@nuevoCostoFinal <> @costoActual)
    BEGIN
        UPDATE Operativo.Servicio
        SET costoFinal = @nuevoCostoFinal
        WHERE idServicio = @idServicio;
    END
END;

-- 5. TGR_DURACIONSERVICIO
-- ** Al insertar un Servicio se actualizará la duracion, en base a sus fechas. ** --
CREATE TRIGGER TGR_DURACIONSERVICIO
ON Operativo.Servicio
AFTER INSERT, UPDATE
AS
BEGIN
    -- Evita la recursión verificando el nivel de anidación
    IF (TRIGGER_NESTLEVEL() > 1) RETURN;

    -- Actualizar la duración en base a las fechas
    UPDATE Operativo.Servicio
    SET duracion = DATEDIFF(DAY, i.fechaInicio, i.fechaFinal)
    FROM Operativo.Servicio S
    INNER JOIN inserted I ON S.idServicio = I.idServicio;
END;

--DISPARADOR(ES) PARA MATERIAL
-- 6. TGR_CALCULA_SUBTOTAL_MATERIAL
-- ** Calcula el subtotalMaterial de un MaterialXServicio. ** --
CREATE TRIGGER TGR_CALCULA_SUBTOTAL_MATERIAL
ON Operativo.MaterialXServicio
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    -- Manejo de inserciones (solo INSERT)
    IF EXISTS (SELECT * FROM inserted) AND NOT EXISTS (SELECT * FROM deleted)
    BEGIN
        -- Actualiza el subtotal multiplicando la cantidad por el costo del material
        UPDATE Operativo.MaterialXServicio
        SET subtotalMaterial = i.cantMaterial * m.precioMaterial
        FROM inserted i
        JOIN Operativo.Material m ON i.idMaterial = m.idMaterial
        WHERE Operativo.MaterialXServicio.idMaterial = i.idMaterial;
    END

    -- Manejo de actualizaciones (UPDATE)
    IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
    BEGIN
        -- Actualiza el subtotal, ajustando la cantidad antigua y nueva
        UPDATE Operativo.MaterialXServicio
        SET subtotalMaterial = (i.cantMaterial * m.precioMaterial)
        FROM inserted i
        JOIN deleted d ON d.idMaterial = i.idMaterial
        JOIN Operativo.Material m ON i.idMaterial = m.idMaterial
        WHERE Operativo.MaterialXServicio.idMaterial = i.idMaterial;
    END

    -- Manejo de eliminaciones (DELETE)
    IF EXISTS (SELECT * FROM deleted) AND NOT EXISTS (SELECT * FROM inserted)
    BEGIN
        -- Si se elimina un material, no es necesario hacer nada con el subtotal en la tabla MaterialXServicio, ya que no será modificado
        -- Aquí podrías agregar lógica si deseas realizar algún tipo de ajuste al subtotal al eliminar, dependiendo de tu lógica de negocio.
        DELETE FROM Operativo.MaterialXServicio
        WHERE idMaterial IN (SELECT idMaterial FROM deleted);
    END
END;

-- 7. TRG_UPDATECOSTOFINAL_MATERIALXSERVICIO
-- ** Al insertar un MaterialXServicio actualiza el costoFinal. ** --
CREATE TRIGGER TRG_UPDATECOSTOFINAL_MATERIALXSERVICIO
ON Operativo.MaterialXServicio
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    DECLARE @idServicio BIGINT;

    -- Obtener el idServicio del registro afectado
    SELECT @idServicio = COALESCE(i.idServicio, d.idServicio)
    FROM inserted i
    FULL OUTER JOIN deleted d ON i.idServicio = d.idServicio;

    -- Calcular el costo final sumando los subtotales de MaterialXServicio y TrabajadorXServicio
    UPDATE Operativo.Servicio
    SET costoFinal = 
        (SELECT COALESCE(SUM(subtotalMaterial), 0)
         FROM Operativo.MaterialXServicio
         WHERE idServicio = @idServicio)
        +
        (SELECT COALESCE(SUM(subtotalTrabajo), 0)
         FROM Operativo.TrabajadorXServicio
         WHERE idServicio = @idServicio)
    WHERE idServicio = @idServicio;
END;

-- 8. TGR_ACTUALIZAR_EXISTENCIAS_MATERIAL
-- ** Al insertar un MaterialXServicio se actualizará la existencia del Material. ** --
CREATE TRIGGER TGR_ACTUALIZAR_EXISTENCIAS_MATERIAL
ON Operativo.MaterialXServicio
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    -- Manejo de inserciones
    IF EXISTS (SELECT * FROM inserted) AND NOT EXISTS (SELECT * FROM deleted)
    BEGIN
        -- Actualizar la existencia sumando las nuevas cantidades
        UPDATE Operativo.Material
        SET existencia = existencia - i.cantMaterial
        FROM inserted i
        WHERE Operativo.Material.idMaterial = i.idMaterial;
    END

    -- Manejo de actualizaciones
    IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
    BEGIN
        -- Actualizar la existencia restando las antiguas cantidades
        UPDATE Operativo.Material
        SET existencia = existencia + d.cantMaterial - i.cantMaterial
        FROM deleted d
        JOIN inserted i ON d.idMaterial = i.idMaterial
        WHERE Operativo.Material.idMaterial = d.idMaterial;
    END

    -- Manejo de eliminaciones
    IF EXISTS (SELECT * FROM deleted) AND NOT EXISTS (SELECT * FROM inserted)
    BEGIN
        -- Restar las cantidades al eliminar registros de DetalleCompra
        UPDATE Operativo.Material
        SET existencia = existencia + d.cantMaterial
        FROM deleted d
        WHERE Operativo.Material.idMaterial = d.idMaterial;
    END
END;

--DISPARADOR(ES) PARA TRABAJADOR
-- 9. TGR_CALCULASUBTOTALTRABAJO
-- ** Al insertar un TrabajoXServicio se aumentará el 15% del costoBase al subtotalTrabajo. ** --
CREATE TRIGGER TGR_CALCULASUBTOTALTRABAJO
ON Operativo.TrabajadorXServicio
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE txs
    SET txs.subtotalTrabajo = ISNULL(dt.costoBase * 1.15, 0)
    FROM Operativo.TrabajadorXServicio txs
    INNER JOIN Operativo.DetalleTrabajador dt ON txs.idTrabajador = dt.idTrabajador
    INNER JOIN inserted i ON i.idServicio = txs.idServicio AND i.idTrabajador = txs.idTrabajador;
END;

-- 10. TRG_UPDATECOSTOFINAL_TRABAJADORXSERVICIO
-- ** El costoFinal de un Servicio se actualizará al insertar un TrabajadorXServicio. ** --
CREATE TRIGGER TRG_UPDATECOSTOFINAL_TRABAJADORXSERVICIO
ON Operativo.TrabajadorXServicio
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    DECLARE @idServicio BIGINT;

    -- Obtener el idServicio del registro insertado, actualizado o eliminado
    SELECT @idServicio = COALESCE((SELECT idServicio FROM inserted), (SELECT idServicio FROM deleted));

    -- Calcular el costo final sumando los subtotales de MaterialXServicio y TrabajadorXServicio
    UPDATE Operativo.Servicio
    SET costoFinal = 
        (SELECT COALESCE(SUM(subtotalMaterial), 0)
         FROM Operativo.MaterialXServicio
         WHERE idServicio = @idServicio)
        +
        (SELECT COALESCE(SUM(subtotalTrabajo), 0)
         FROM Operativo.TrabajadorXServicio
         WHERE idServicio = @idServicio)
    WHERE idServicio = @idServicio;
END;
