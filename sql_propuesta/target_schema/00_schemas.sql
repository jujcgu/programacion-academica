-- ============================================================================
-- ARTEFACTO: 00_schemas.sql
-- DESCRIPCIÓN: Definición y creación de esquemas lógicos del sistema
-- PROYECTO: Sistema de Programación Académica (p_academica-main)
-- MOTOR OBJETIVO: Microsoft SQL Server 2016+ / Azure SQL Database / T-SQL ANSI
-- ============================================================================

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- 1. Esquema dbo (Esquema por defecto del catálogo institucional)
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'dbo')
BEGIN
    EXEC('CREATE SCHEMA [dbo]');
END
GO

-- 2. Esquema programacionacademica (Núcleo de programación, solicitudes y gestión)
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'programacionacademica')
BEGIN
    EXEC('CREATE SCHEMA [programacionacademica]');
END
GO

-- 3. Esquema proyectos (Proyectos de extensión e investigación y proyección social)
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'proyectos')
BEGIN
    EXEC('CREATE SCHEMA [proyectos]');
END
GO

-- 4. Esquema auditoria (Arquitectura de auditoría temporal y trazabilidad de eventos)
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'auditoria')
BEGIN
    EXEC('CREATE SCHEMA [auditoria]');
END
GO

-- 5. Esquema acreditacion (Catálogo de campos detallados y acreditación institucional)
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'acreditacion')
BEGIN
    EXEC('CREATE SCHEMA [acreditacion]');
END
GO
