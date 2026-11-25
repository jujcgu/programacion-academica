USE [academia3000_sergiomartinez]
GO

/****** Objeto: UserDefinedFunction [token].[getTokenInicioSesion] Fecha de script: 25/11/2026 11:16:02 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



/*
Autor: Sergio Gaspar Llanos
Fecha: 25 junio 2020
Descripcion: Funcion para generar tokens que se envian
al modulo de generacion de codigos de verificacion.
*/
CREATE FUNCTION [token].[getTokenInicioSesion](@atributos varchar(8000))
RETURNS varchar(100)
AS
BEGIN
	DECLARE @key varchar(64),
			@keyEncriptada varbinary(64),
			@antes varchar(4),
			@despues varchar(4),
			@fechaActual varchar(10),
			@token varchar(100)

	SELECT @key = 'G3n3rar-codIGO;SESion..';
	SELECT @antes = 'Bv.,43lL.h..';
	SELECT @despues = 'w7X;87Fir9,';
	
	SELECT @key = [dbo].[VarBinToHexStr](HASHBYTES('SHA1', @key));
	SELECT @keyEncriptada = HashBytes('MD5', @antes + @key + @despues)
	SELECT @key = [dbo].[VarBinToHexStr](HASHBYTES('SHA1', @keyEncriptada));
	
	SELECT @fechaActual =CONVERT(VARCHAR(10), getdate(), 105);
	SELECT @token= [dbo].[VarBinToHexStr](HASHBYTES('SHA1', @atributos+@fechaActual));

	RETURN @token;
END

GO


