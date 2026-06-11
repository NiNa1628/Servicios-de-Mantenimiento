# 🛠️ Servicios de Mantenimiento – Sistema de Gestión de Servicios

Este proyecto consiste en el diseño e implementación de una base de datos relacional para la administración integral de una empresa de servicios de mantenimiento. La solución permite gestionar información relacionada con clientes, proveedores, compras, trabajadores, materiales y servicios, garantizando la integridad y consistencia de los datos mediante el uso de restricciones y automatizaciones.

## ✨ Características principales

* Gestión de clientes y sus domicilios.
* Administración de proveedores y compras realizadas.
* Registro y control de materiales utilizados en los servicios.
* Gestión de trabajadores y sus especialidades.
* Asignación de trabajadores a servicios específicos.
* Relación entre servicios y materiales empleados.
* Validación automática de información mediante restricciones y triggers.
* Implementación de interfaces gráficas conectadas a la base de datos.
* Elaboración de manuales técnicos y de usuario.

## 🏗️ Arquitectura de la base de datos

La solución fue estructurada utilizando dos esquemas principales:

### 📌 Esquema Comercial

Encargado de la gestión administrativa y comercial.

**Tablas:**

* Cliente
* DomicilioCliente
* Proveedor
* Compra
* DetalleCompra

### ⚙️ Esquema Operativo

Responsable de la operación y ejecución de los servicios.

**Tablas:**

* Servicio
* Material
* MaterialXServicio
* Trabajador
* DetalleTrabajador
* TrabajadorXServicio

## 🛠️ Tecnologías utilizadas

### Base de datos

* SQL Server
* PostgreSQL

### Lenguajes de programación

* C#
* Java
* SQL

### Herramientas y conceptos aplicados

* Diseño de bases de datos relacionales.
* Normalización de datos.
* Llaves primarias y foráneas.
* Restricciones de integridad.
* Triggers.
* Consultas SQL.
* Integración entre aplicaciones y bases de datos.

## 🎯 Objetivo del proyecto

Desarrollar una solución tecnológica capaz de optimizar la gestión operativa y administrativa de una empresa de mantenimiento, facilitando el almacenamiento, consulta y manipulación eficiente de la información.

## 📚 Aprendizajes obtenidos

Durante el desarrollo del proyecto fortalecí conocimientos en:

* Modelado de bases de datos complejas.
* Implementación de reglas de negocio mediante SQL.
* Desarrollo de aplicaciones conectadas a bases de datos.
* Integración de SQL Server con C#.
* Integración de PostgreSQL con Java.
* Elaboración de documentación técnica y manuales de usuario.
* Trabajo con arquitecturas orientadas a la separación de responsabilidades.

## 📁 Recursos incluidos

Este repositorio contiene:

* Scripts de creación de las bases de datos.
* Interfaces gráficas desarrolladas para interactuar con el sistema.
* Manuales de usuario.
* Manuales técnicos para programadores.
* Videos explicativos sobre el funcionamiento del sistema.

## 🚀 Cómo ejecutar el proyecto

1. Restaurar o ejecutar los scripts correspondientes a la base de datos.
2. Configurar las conexiones necesarias según el entorno seleccionado:

   * SQL Server + C#
   * PostgreSQL + Java
3. Ejecutar la aplicación correspondiente.
4. Consultar los manuales incluidos para la configuración detallada.

## 👩‍💻 Autora

Claudia Karina González Medina

GitHub: https://github.com/NiNa1628
