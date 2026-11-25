USE [academia3000_sergiomartinez]
GO

/****** Objeto: UserDefinedFunction [dbo].[encriptarClaveReal] Fecha de script: 25/11/2026 11:13:47 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		juan castro
-- Create date: 29/03/2012
-- Description:	Encriptar clave real
-- =============================================
CREATE FUNCTION [dbo].[encriptarClaveReal] 
(
	-- Add the parameters for the function here
	@clave_plana varchar(64)
)
RETURNS varchar(64)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @claveReal varchar(64),
			@clavePlana varchar(64),
			@claveEncriptada varbinary(64),
			@antes varchar(4),
			@despues varchar(4)

	-- Add the T-SQL statements to compute the return value here
	SELECT @antes = '16.3.2012:';
	SELECT @despues = 'Su;NA;mi;';
	
	SELECT @clavePlana = [dbo].[VarBinToHexStr](HASHBYTES('SHA1', @clave_plana));	
	
	SELECT @claveEncriptada = HashBytes('MD5', @antes + @clavePlana + @despues)
	
	SELECT @claveReal = [dbo].[VarBinToHexStr](HASHBYTES('SHA1', @claveEncriptada));
	
	-- Return the result of the function
	RETURN @claveReal

END
GO


