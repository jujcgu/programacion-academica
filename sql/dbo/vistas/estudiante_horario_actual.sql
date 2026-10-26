USE [academia3000_sergiomartinez]
GO

/****** Objeto: View [dbo].[estudiante_horario_actual] Fecha de script: 26/10/2026 9:49:26 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[estudiante_horario_actual]
AS
SELECT     CONVERT(VARCHAR(MAX), CONVERT(date, eo.eso_fecha)) + '--' + CONVERT(VARCHAR(MAX), eo.dia_codigo) + '--' + CONVERT(VARCHAR(MAX), eo.hra_codigo) AS date, 
                      eo.eso_fecha, eo.dia_codigo, eo.hra_codigo, m.est_codigo, mc.cur_codigo, eo.eso_actividad, eo.eso_subgrupo, est.per_codigo, pro.nia_codigo
FROM         dbo.matricula AS m with(nolock) INNER JOIN
                      dbo.matricula_curso_actual AS mc with(nolock) ON m.mat_codigo = mc.mat_codigo INNER JOIN
                      dbo.estudiante AS est with(nolock) ON m.est_codigo = est.est_codigo INNER JOIN
					  dbo.programa AS pro WITH(NOLOCK) ON est.pro_codigo = pro.pro_codigo INNER JOIN
                      dbo.espacio_ocupacion AS eo with(nolock) ON mc.cur_codigo = eo.eso_actividad
WHERE     (m.cal_codigo IN
                          (SELECT     Value
                            FROM          dbo.Split
                                                       ((SELECT     wep_valor
                                                           FROM         dbo.web_parametro with(nolock)
                                                           WHERE     (wep_nombre = 'MATRICULA_PREGRADO_POSGRADO_CALENDARIO_ACTUAL')), ',') AS Split_1)) AND (mc.maa_codigo IN (1, 2)) AND 
                      (eo.eso_subgrupo IN ('00', mc.mac_subgrupo))
GROUP BY eo.eso_fecha, eo.dia_codigo, eo.hra_codigo, m.est_codigo, mc.cur_codigo, eo.eso_actividad, eo.eso_subgrupo, est.per_codigo, pro.nia_codigo

GO

EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[32] 4[14] 2[37] 3) )"
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
         Begin Table = "m"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 125
               Right = 261
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "mc"
            Begin Extent = 
               Top = 6
               Left = 299
               Bottom = 125
               Right = 523
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "est"
            Begin Extent = 
               Top = 6
               Left = 561
               Bottom = 125
               Right = 775
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "eo"
            Begin Extent = 
               Top = 6
               Left = 813
               Bottom = 125
               Right = 1027
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
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
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'estudiante_horario_actual'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'estudiante_horario_actual'
GO


