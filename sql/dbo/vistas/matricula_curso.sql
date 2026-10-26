USE [academia3000_sergiomartinez]
GO

/****** Objeto: View [dbo].[matricula_curso] Fecha de script: 26/10/2026 8:57:43 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[matricula_curso]
AS
SELECT     mac_codigo, mat_codigo, cur_codigo, mac_subgrupo, mac_estado, mac_nota, mac_habilitacion, mac_perdio_fallas, mac_definitiva, maf_codigo, res_codigo, 
                      paa_codigo, mac_novedad, maa_codigo, mac_usuario, mac_ip_nota, mac_clave, mac_cliente, mac_fecha_nota, paa_codigo_anterior, sippa_sedcodigo, 
                      sippa_calcodigo, sippa_estcodigo, sippa_progcodigo, sippa_plancodigo, sippa_asicodigo, sippa_horasasignatura, sippa_grucodigo, sippa_subgrucodigo, 
                      sippa_cursemestre, sippa_curasignatura, sippa_curnomasigna, sippa_curforma, sippa_curautorizacion, temporal_null, mac_usuario_nota, mac_cliente_nota, 
                      esc_codigo, esc_nombre, mac_fecha_hora, 'ACTUAL' AS tabla
FROM         dbo.matricula_curso_actual
UNION
SELECT     mac_codigo, mat_codigo, cur_codigo, mac_subgrupo, mac_estado, mac_nota, mac_habilitacion, mac_perdio_fallas, mac_definitiva, maf_codigo, res_codigo, 
                      paa_codigo, mac_novedad, maa_codigo, mac_usuario, mac_ip_nota, mac_clave, mac_cliente, mac_fecha_nota, paa_codigo_anterior, sippa_sedcodigo, 
                      sippa_calcodigo, sippa_estcodigo, sippa_progcodigo, sippa_plancodigo, sippa_asicodigo, sippa_horasasignatura, sippa_grucodigo, sippa_subgrucodigo, 
                      sippa_cursemestre, sippa_curasignatura, sippa_curnomasigna, sippa_curforma, sippa_curautorizacion, temporal_null, mac_usuario_nota, mac_cliente_nota, 
                      esc_codigo, esc_nombre, mac_fecha_hora, 'HISTORICO' AS tabla
FROM         dbo.matricula_curso_historico
UNION
SELECT     mac_codigo, mat_codigo, cur_codigo, mac_subgrupo, mac_estado, mac_nota, mac_habilitacion, mac_perdio_fallas, mac_definitiva, maf_codigo, res_codigo, 
                      paa_codigo, mac_novedad, maa_codigo, mac_usuario, mac_ip_nota, mac_clave, mac_cliente, mac_fecha_nota, paa_codigo_anterior, sippa_sedcodigo, 
                      sippa_calcodigo, sippa_estcodigo, sippa_progcodigo, sippa_plancodigo, sippa_asicodigo, sippa_horasasignatura, sippa_grucodigo, sippa_subgrucodigo, 
                      sippa_cursemestre, sippa_curasignatura, sippa_curnomasigna, sippa_curforma, sippa_curautorizacion, temporal_null, mac_usuario_nota, mac_cliente_nota, 
                      esc_codigo, esc_nombre, mac_fecha_hora, 'MULTICURSO' AS tabla
FROM         dbo.matricula_multicurso
GO

EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[13] 4[22] 2[47] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'matricula_curso'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'matricula_curso'
GO


