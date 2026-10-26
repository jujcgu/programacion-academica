USE [academia3000_sergiomartinez]
GO

/****** Objeto: View [dbo].[usuario_docente] Fecha de script: 26/10/2026 9:09:04 a. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[usuario_docente]
AS
SELECT     dbo.usuario_docentes.up, dbo.usuario_docentes.us, dbo.usuario_docentes.istipo, dbo.usuario_docentes.ischange, dbo.usuario_docentes.state, 
                      dbo.usuario_docentes.sys, dbo.usuario_grupo.usg_grupo, dbo.grupo.gru_nombre, dbo.usuario_grupo.usg_usuario, dbo.usuario_docentes.uid, dbo.grupo.gru_id, 
                      dbo.usuario_grupo.usg_estado, dbo.usuario_grupo.usg_uaa, dbo.usuario_docentes.us_encriptado
FROM         dbo.grupo INNER JOIN
                      dbo.usuario_grupo ON dbo.grupo.gru_codigo = dbo.usuario_grupo.usg_grupo INNER JOIN
                      dbo.usuario_docentes ON dbo.usuario_grupo.usg_usuario = dbo.usuario_docentes.uid
WHERE     (dbo.grupo.gru_id = 'DOCENTE') OR
                      (dbo.grupo.gru_id = 'JEFE_PROGRAMA') OR
                      (dbo.grupo.gru_id = 'JEFE_DEPARTAMENTO')
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
         Begin Table = "grupo"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 106
               Right = 228
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "usuario_grupo"
            Begin Extent = 
               Top = 6
               Left = 266
               Bottom = 121
               Right = 456
            End
            DisplayFlags = 280
            TopColumn = 1
         End
         Begin Table = "usuario_docentes"
            Begin Extent = 
               Top = 1
               Left = 553
               Bottom = 216
               Right = 743
            End
            DisplayFlags = 280
            TopColumn = 5
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 14
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
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
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'usuario_docente'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'usuario_docente'
GO


