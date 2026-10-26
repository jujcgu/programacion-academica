USE [academia3000_sergiomartinez]
GO

/****** Objeto: View [dbo].[notas_total] Fecha de script: 26/10/2026 9:55:54 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




CREATE VIEW [dbo].[notas_total]
AS
SELECT				
					dbo.calendario.cal_nombre, dbo.matricula_curso.mac_subgrupo, dbo.matricula_curso.mac_nota, dbo.matricula_curso.maa_codigo, dbo.matricula_curso.cur_codigo, 
                      dbo.matricula_curso.mac_habilitacion, dbo.matricula_curso.mac_definitiva, dbo.matricula_forma.maf_nombre, dbo.matricula_curso.paa_codigo, 
                      dbo.matricula.est_codigo, dbo.curso.cur_codigo AS Expr1, dbo.plan_academico_asignatura.paa_semestre, dbo.plan_academico_asignatura.paa_credito, 
                      asignatura2.asi_codigo, dbo.plan_academico_asignatura.pla_codigo, asignatura1.asi_nombre_corto, asignatura2.asi_nombre,asignatura2.asi_nombre_corto AS asi_nombre_corto_paa,asignatura1.asi_nombre AS asi_nom2, 
                      asignatura1.asi_codigo AS Expr3, COALESCE(CASE WHEN asignatura1.asi_creditos IS NULL THEN asignatura3.asi_creditos ELSE  asignatura1.asi_creditos END,
			CASE WHEN asignatura3.asi_creditos IS NULL THEN dbo.plan_academico_asignatura.paa_credito ELSE asignatura3.asi_creditos END) AS asi_creditos, dbo.matricula_curso.sippa_curnomasigna, dbo.matricula_curso.sippa_asicodigo, 
                      dbo.matricula_curso.sippa_cursemestre, dbo.matricula_curso.mac_fecha_nota, dbo.matricula_curso.esc_codigo, dbo.matricula_curso.esc_nombre, 
                      dbo.curso.tes_codigo, dbo.matricula_curso.tabla,
                      dbo.plan_academico_asignatura.paa_intensidad, dbo.matricula_autorizacion.maa_nombre, dbo.plan_academico_asignatura.paa_multi_asignatura, 
                      dbo.plan_academico_asignatura.paa_plan_academico
FROM				dbo.asignatura AS asignatura2 INNER JOIN
                      dbo.plan_academico_asignatura ON asignatura2.asi_codigo = dbo.plan_academico_asignatura.asi_codigo RIGHT OUTER JOIN
                      dbo.calendario INNER JOIN
                      dbo.matricula_curso INNER JOIN
                      dbo.matricula ON dbo.matricula_curso.mat_codigo = dbo.matricula.mat_codigo INNER JOIN
                      dbo.matricula_autorizacion ON dbo.matricula_curso.maa_codigo = dbo.matricula_autorizacion.maa_codigo INNER JOIN
                      dbo.matricula_forma ON dbo.matricula_curso.maf_codigo = dbo.matricula_forma.maf_codigo ON dbo.calendario.cal_codigo = dbo.matricula.cal_codigo ON 
                      dbo.plan_academico_asignatura.paa_codigo = dbo.matricula_curso.paa_codigo LEFT OUTER JOIN
                      dbo.curso ON dbo.matricula_curso.cur_codigo = dbo.curso.cur_codigo LEFT OUTER JOIN
                      dbo.asignatura AS asignatura1 ON dbo.curso.asi_codigo = asignatura1.asi_codigo
			LEFT JOIN dbo.asignatura AS asignatura3 ON dbo.matricula_curso.sippa_asicodigo LIKE asignatura3.asi_codigo




GO

EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1[50] 2[25] 3) )"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4[30] 2[40] 3) )"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2[66] 3) )"
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
         Configuration = "(H (1[50] 2) )"
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
      ActivePaneConfig = 10
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "asignatura2"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 121
               Right = 247
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "plan_academico_asignatura"
            Begin Extent = 
               Top = 0
               Left = 299
               Bottom = 115
               Right = 509
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "calendario"
            Begin Extent = 
               Top = 274
               Left = 619
               Bottom = 389
               Right = 809
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "matricula_curso"
            Begin Extent = 
               Top = 7
               Left = 594
               Bottom = 122
               Right = 784
            End
            DisplayFlags = 280
            TopColumn = 38
         End
         Begin Table = "matricula"
            Begin Extent = 
               Top = 168
               Left = 349
               Bottom = 283
               Right = 539
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "matricula_forma"
            Begin Extent = 
               Top = 161
               Left = 667
               Bottom = 246
               Right = 857
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "curso"
            Begin Extent = 
               Top = 156
               Left = 79
               Bottom = 271
               Right = 269
        ' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'notas_total'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane2', @value=N'    End
            DisplayFlags = 280
            TopColumn = 29
         End
         Begin Table = "asignatura1"
            Begin Extent = 
               Top = 283
               Left = 72
               Bottom = 398
               Right = 281
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      PaneHidden = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      PaneHidden = 
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
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'notas_total'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=2 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'notas_total'
GO


