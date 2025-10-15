Servicios de Mantenimiento – Base de Datos

Este proyecto implementa la base de datos ServiciosdeMantenimiento, diseñada para gestionar clientes, proveedores, compras, servicios, trabajadores, materiales y sus relaciones.
Está organizada bajo una arquitectura de dos esquemas principales: Comercial y Operativo, con claves foráneas, restricciones, reglas y triggers automáticos.

Estructura del Proyecto
Esquemas
1. Comercial
Gestiona la información administrativa y de negocio:
Cliente – Datos de los clientes.
DomicilioCliente – Direcciones asociadas a cada cliente.
Proveedor – Información de los proveedores.
Compra – Compras realizadas a proveedores.
DetalleCompra – Materiales adquiridos en cada compra.

2. Operativo
Gestiona la operación de los servicios:
Servicio – Servicios ofrecidos a los clientes.
Material – Materiales utilizados en los servicios.
MaterialXServicio – Relación entre materiales y servicios.
Trabajador – Datos personales de los trabajadores.
DetalleTrabajador – Profesión y costo base de cada trabajador.
TrabajadorXServicio – Asignación de trabajadores a servicios.

El proyecto fue realizado en SQLServer con conexión a C# y en PosgreSQL con conexión a Java.

El proyecto cuanta con manuales de usuario (vídeos explicativos), manuales de programador y las bases de datos con su interfaz gráfica.
