Attribute VB_Name = "ModAreas"
Option Explicit

'LAS GUARDAMOS PARA PROCESAR LOS MPs y sabes si borrar personajes
Public MinLimiteX As Integer
Public MaxLimiteX As Integer
Public MinLimiteY As Integer
Public MaxLimiteY As Integer

Public Sub CambioDeArea(ByVal X As Byte, ByVal Y As Byte)
    Dim loopX As Byte, loopY As Byte
    
    MinLimiteX = (X \ 9 - 1) * 9
    MaxLimiteX = MinLimiteX + 26
    
    MinLimiteY = (Y \ 9 - 1) * 9
    MaxLimiteY = MinLimiteY + 26
    
    For loopX = 1 To 100
        For loopY = 1 To 100
            
            If loopY < MinLimiteY Or loopY > MaxLimiteY Or loopX < MinLimiteX Or loopX > MaxLimiteX Then
                'Erase NPCs
                If MapData(loopX, loopY).CharIndex > 0 Then
                    If MapData(loopX, loopY).CharIndex <> UserCharIndex Then
                        Call EraseChar(MapData(loopX, loopY).CharIndex)
                    End If
                End If
                
                'Erase OBJs
                MapData(loopX, loopY).Obj.Grh.GrhIndex = 0
            End If
        Next loopY
    Next loopX
    
    If frmPlataforma.Visible Then
        Unload frmPlataforma
    End If
End Sub
