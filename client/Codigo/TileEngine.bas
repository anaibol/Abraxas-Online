Attribute VB_Name = "ModTileEngine"
Option Explicit

Private Const GrhFogata As Integer = 1521

Private Const GrhPortal As Integer = 669

'Sets a Grh animation to loop indefinitely.
Private Const INFINITE_LOOPS As Integer = -1

'Encabezado bmp
Type BITMAPFILEHEADER
    bfType As Integer
    bfSize As Long
    bfReserved1 As Integer
    bfReserved2 As Integer
    bfOffBits As Long
End Type

'Info del encabezado del bmp
Type BITMAPINFOHEADER
    biSize As Long
    biWidth As Long
    biHeight As Long
    biPlanes As Integer
    biBitCount As Integer
    biCompression As Long
    biSizeImage As Long
    biXPelsPerMeter As Long
    biYPelsPerMeter As Long
    biClrUsed As Long
    biClrImportant As Long
End Type

'Posicion en un mapa
Public Type Position
    X As Long
    Y As Long
End Type

'Posicion en el Mundo
Public Type WorldPos
    map As Integer
    X As Integer
    Y As Integer
End Type

'Contiene info acerca de donde se puede encontrar un grh tama�o y animacion
Public Type GrhData
    sX As Integer
    sY As Integer
    
    FileNum As Long
    
    PixelWidth As Integer
    PixelHeight As Integer
    
    TileWidth As Single
    TileHeight As Single
    
    NumFrames As Integer
    Frames() As Long
    
    Speed As Single
End Type

'apunta a una estructura grhdata y mantiene la animacion
Public Type Grh
    GrhIndex As Integer
    FrameCounter As Single
    Speed As Single
    Started As Byte
    Loops As Integer
End Type

'List   a de cuerpos
Public Type BodyData
    Walk(eHeading.NORTH To eHeading.WEST) As Grh
    HeadOffset As Position
End Type

'Lista de cabezas
Public Type HeadData
    Head(eHeading.NORTH To eHeading.WEST) As Grh
End Type

'Lista de las animaciones de las armas
Type WeaponAnimData
    WeaponWalk(eHeading.NORTH To eHeading.WEST) As Grh
End Type

'Lista de las animaciones de los escudos
Type ShieldAnimData
    ShieldWalk(eHeading.NORTH To eHeading.WEST) As Grh
End Type


'Apariencia del personaje
Public Type Char
    Active As Byte
    Heading As eHeading
    Pos As Position
    
    iHead As Integer
    iBody As Integer
    Body As BodyData
    Head As HeadData
    Casco As HeadData
    Arma As WeaponAnimData
    Escudo As ShieldAnimData
    
    fX As Grh
    FxIndex As Integer
        
    Nombre As String
    
    Guilda As String
    AlineacionGuilda As Byte
    
    ScrollDirectionX As Integer
    ScrollDirectionY As Integer
    
    Moving As Boolean
    MoveOffsetX As Single
    MoveOffsetY As Single
    
    ScreenX As Single
    ScreenY As Single
    
    Pie As Boolean
    Muerto As Boolean
    Invisible As Boolean
    Paralizado As Boolean
    Priv As Byte
    Lvl As Byte
    CompaIndex As Byte
    MascoIndex As Byte
    Quieto As Boolean
    EsUser As Boolean
End Type

'Info de un objeto
Public Type ObjInfo
    Index As Integer
    Amount As Long
    Grh As Grh
    Name As String
    ObjType As eObjType
End Type

'Tipo de las celdas del mapa
Public Type MapBlock
    Graphic(1 To 4) As Grh
    CharIndex As Integer
    
    Obj As ObjInfo
    TileExit As WorldPos
    Blocked As Boolean
    
    Trigger As Integer
    
    fX As Grh
    FxIndex As Integer
End Type

'Info de cada mapa
Public Type MapInfoBlock
    Name As String
    Version As Integer
    Zone As String
    Music As Byte
    Top As Byte
    Left As Byte
End Type

'Bordes del mapa
Public MinXBorder As Byte
Public MaxXBorder As Byte
Public MinYBorder As Byte
Public MaxYBorder As Byte

'Status del user
Public UserIndex As Integer
Public UserMoving As Byte
Public UserBody As Integer
Public UserHead As Integer
Public UserPos As Position 'Posicion
Public AddtoUserPos As Position 'Si se mueve
Public PrevUserPos As Position 'Si se mueve
Public UserCharIndex As Integer
Public UserMap As Integer

Public EngineRun As Boolean

Public FPS As Long
Public FramesPerSecCounter As Long
Private fpsLastCheck As Long

'Tama�o del la vista en Tiles
Private WindowTileWidth As Integer
Private WindowTileHeight As Integer

Private HalfWindowTileWidth As Integer
Private HalfWindowTileHeight As Integer

'Offset del desde 0,0 del main view
Private MainViewTop As Integer
Private MainViewLeft As Integer

'Cuantos tiles el engine mete en el BUFFER cuando
'dibuja el mapa. Ojo un tama�o muy grande puede
'volver el engine muy lento
Public TileBufferSize As Integer

Private TileBufferPixelOffsetX As Integer
Private TileBufferPixelOffsetY As Integer

'Number of pixels the engine scrolls per frame. MUST divide evenly into pixels per tile
Public ScrollPixelsPerFrameX As Integer
Public ScrollPixelsPerFrameY As Integer

Dim timerElapsedTime As Single
Dim timerTicksPerFrame As Single
Dim engineBaseSpeed As Single


Public NumBodies As Integer
Public Numheads As Integer
Public NumFxs As Integer

Public NumChars As Integer
Public LastChar As Integer
Public NumWeaponAnims As Integer
Public NumShieldAnims As Integer

Private MainDestRect   As RECT
Private MainViewRect   As RECT
Private BackBufferRect As RECT

Private MainViewWidth As Integer
Private MainViewHeight As Integer

Public MouseTileX As Byte
Public MouseTileY As Byte

'�?�?�?�?�?�?�?�?�?�Graficos�?�?�?�?�?�?�?�?�?�?�?
Public GrhData() As GrhData 'Guarda todos los grh
Public BodyData() As BodyData
Public HeadData() As HeadData
Public FxData() As tIndiceFx
Public WeaponAnimData() As WeaponAnimData
Public ShieldAnimData() As ShieldAnimData
Public CascoAnimData() As HeadData
'�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?

'�?�?�?�?�?�?�?�?�?�Mapa?�?�?�?�?�?�?�?�?�?�?�?
Public MapData() As MapBlock 'Mapa
Public MapInfo() As MapInfoBlock 'Info acerca del mapa en uso
'�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?�?

Public bRain        As Boolean 'est� raineando?
Public bTecho       As Boolean 'hay techo?

Private RLluvia(7)  As RECT  'RECT de la lluvia
Private iFrameIndex As Byte  'Frame actual de la LL
Private llTick      As Long  'Contador
Private LTLluvia(4) As Integer

Public Charlist(1 To 10000) As Char

'Used by GetTextExtentPoint32
Private Type size
    cX As Long
    cY As Long
End Type

Public Enum PlayLoop
    plNone = 0
    plLluviain = 1
    plLluviaout = 2
End Enum

Private Declare Function BltAlphaFast Lib "vbabdx" (ByRef lpDDSDest As Any, ByRef lpDDSSource As Any, ByVal iWidth As Long, ByVal iHeight As Long, _
        ByVal pitchSrc As Long, ByVal pitchDst As Long, ByVal dwMode As Long) As Long
Private Declare Function BltEfectoNoche Lib "vbabdx" (ByRef lpDDSDest As Any, ByVal iWidth As Long, ByVal iHeight As Long, _
        ByVal pitchDst As Long, ByVal dwMode As Long) As Long

Private Declare Function vbDABLalphablend16 Lib "vbDABL" (ByVal iMode As Integer, ByVal bColorKey As Integer, _
        ByRef sPtr As Any, ByRef dPtr As Any, ByVal iAlphaVal As Integer, ByVal iWidth As Integer, ByVal iHeight As Integer, _
ByVal isPitch As Integer, ByVal idPitch As Integer, ByVal iColorKey As Integer) As Integer
        Public Declare Function vbDABLcolorblend16555 Lib "vbDABL" (ByRef sPtr As Any, ByRef dPtr As Any, ByVal alpha_val%, _
ByVal Width%, ByVal Height%, ByVal sPitch%, ByVal dPitch%, ByVal rVal%, ByVal gVal%, ByVal bVal%) As Long
        Public Declare Function vbDABLcolorblend16565 Lib "vbDABL" (ByRef sPtr As Any, ByRef dPtr As Any, ByVal alpha_val%, _
ByVal Width%, ByVal Height%, ByVal sPitch%, ByVal dPitch%, ByVal rVal%, ByVal gVal%, ByVal bVal%) As Long
        Public Declare Function vbDABLcolorblend16555ck Lib "vbDABL" (ByRef sPtr As Any, ByRef dPtr As Any, ByVal alpha_val%, _
ByVal Width%, ByVal Height%, ByVal sPitch%, ByVal dPitch%, ByVal rVal%, ByVal gVal%, ByVal bVal%) As Long
        Public Declare Function vbDABLcolorblend16565ck Lib "vbDABL" (ByRef sPtr As Any, ByRef dPtr As Any, ByVal alpha_val%, _
ByVal Width%, ByVal Height%, ByVal sPitch%, ByVal dPitch%, ByVal rVal%, ByVal gVal%, ByVal bVal%) As Long

'Very percise counter 64bit system counter
Private Declare Function QueryPerformanceFrequency Lib "kernel32" (lpFrequency As Currency) As Long
Private Declare Function QueryPerformanceCounter Lib "kernel32" (lpPerformanceCount As Currency) As Long

'Text width computation. Needed to center text.
Private Declare Function GetTextExtentPoint32 Lib "gdi32" Alias "GetTextExtentPoint32A" (ByVal hdc As Long, ByVal lpsz As String, ByVal cbString As Long, lpSize As size) As Long

Public Declare Function GetDC Lib "user32" (ByVal hWnd As Long) As Long
Public Declare Function ReleaseDC Lib "user32" (ByVal hWnd As Long, ByVal hdc As Long) As Long

Private Declare Function SetPixel Lib "gdi32" (ByVal hdc As Long, ByVal X As Long, ByVal Y As Long, ByVal crColor As Long) As Long
Private Declare Function GetPixel Lib "gdi32" (ByVal hdc As Long, ByVal X As Long, ByVal Y As Long) As Long

'RENDERCHARNAME
Private CharName As String
Private CharColor As Long

'RENDEROBJNAME
Private ObjName As String
Private ObjType As eObjType
Private ObjX As Integer
Private ObjY As Integer

'RENDERDAMAGE
Private Damage As String
Private startTime As Long
Private X As Integer
Private Y As Integer
Private SUBe As Integer

'RENDERCHARDAMAGE
Private startTime4 As Long
Private SUBe4 As Integer
Private CharX As Integer
Private CharY As Integer

Public AttackerCharIndex As Integer
Public CharDamage As String
Public CharDamage2 As String

'RENDERCHARHP
Public CharMinHP As Byte
Public TempCharHP As Integer
Private CharX2 As Integer
Private CharY2 As Integer

Public AttackedCharIndex As Integer

Public SelectedCharIndex As Integer

'RENDEREXP
Private Exp As String
Private StartTime2 As Long
Private Y2 As Integer
Private X2 As Integer
Private SUBe2 As Integer

'RENDERGLD
Private Gld As Long
Private StartTime3 As Long
Private Y3 As Integer
Private X3 As Integer
Private SUBe3 As Integer

Public DamageType As Byte

Public CharDamageType As Byte

Public Sub CargarCabezas()
    Dim n As Integer
    Dim i As Long
    Dim Numheads As Integer
    Dim Miscabezas() As tIndiceCabeza
    
    n = FreeFile()
    Open DataPath & "Cabezas.ind" For Binary Access Read As #n
    
    'cabecera
    Get #n, , MiCabecera
    
    'num de cabezas
    Get #n, , Numheads
    
    'Resize array
    ReDim HeadData(0 To Numheads) As HeadData
    ReDim Miscabezas(0 To Numheads) As tIndiceCabeza
    
    For i = 1 To Numheads
        Get #n, , Miscabezas(i)
        
        If Miscabezas(i).Head(1) Then
            Call InitGrh(HeadData(i).Head(1), Miscabezas(i).Head(1), 0)
            Call InitGrh(HeadData(i).Head(2), Miscabezas(i).Head(2), 0)
            Call InitGrh(HeadData(i).Head(3), Miscabezas(i).Head(3), 0)
            Call InitGrh(HeadData(i).Head(4), Miscabezas(i).Head(4), 0)
        End If
    Next i
    
    Close #n
End Sub

Public Sub CargarCascos()
    Dim n As Integer
    Dim i As Long
    Dim NumCascos As Integer

    Dim Miscabezas() As tIndiceCabeza
    
    n = FreeFile()
    Open DataPath & "Cascos.ind" For Binary Access Read As #n
    
    'cabecera
    Get #n, , MiCabecera
    
    'num de cabezas
    Get #n, , NumCascos
    
    'Resize array
    ReDim CascoAnimData(0 To NumCascos) As HeadData
    ReDim Miscabezas(0 To NumCascos) As tIndiceCabeza
    
    For i = 1 To NumCascos
        Get #n, , Miscabezas(i)
        
        If Miscabezas(i).Head(1) Then
            Call InitGrh(CascoAnimData(i).Head(1), Miscabezas(i).Head(1), 0)
            Call InitGrh(CascoAnimData(i).Head(2), Miscabezas(i).Head(2), 0)
            Call InitGrh(CascoAnimData(i).Head(3), Miscabezas(i).Head(3), 0)
            Call InitGrh(CascoAnimData(i).Head(4), Miscabezas(i).Head(4), 0)
        End If
    Next i
    
    Close #n
End Sub

Public Sub CargarCuerpos()
    Dim n As Integer
    Dim i As Long
    Dim NumCuerpos As Integer
    Dim MisCuerpos() As tIndiceCuerpo
    
    n = FreeFile()
    Open DataPath & "Cuerpos.ind" For Binary Access Read As #n
    
    Get #n, , MiCabecera
    
    Get #n, , NumCuerpos
    
    'Resize array
    ReDim BodyData(0 To NumCuerpos) As BodyData
    ReDim MisCuerpos(0 To NumCuerpos) As tIndiceCuerpo
    
    For i = 1 To NumCuerpos
        Get #n, , MisCuerpos(i)
        
        If MisCuerpos(i).Body(1) Then
            InitGrh BodyData(i).Walk(1), MisCuerpos(i).Body(1), 0
            InitGrh BodyData(i).Walk(2), MisCuerpos(i).Body(2), 0
            InitGrh BodyData(i).Walk(3), MisCuerpos(i).Body(3), 0
            InitGrh BodyData(i).Walk(4), MisCuerpos(i).Body(4), 0
            
            BodyData(i).HeadOffset.X = MisCuerpos(i).HeadOffsetX
            BodyData(i).HeadOffset.Y = MisCuerpos(i).HeadOffsetY
        End If
    Next i
    
    Close #n
End Sub

Public Sub CargarFxs()
    Dim n As Integer
    Dim i As Long
    Dim NumFxs As Integer
    
    n = FreeFile()
    Open DataPath & "Fx.ind" For Binary Access Read As #n
    
    Get #n, , MiCabecera
    
    Get #n, , NumFxs
    
    'Resize array
    ReDim FxData(1 To NumFxs) As tIndiceFx
    
    For i = 1 To NumFxs
        Get #n, , FxData(i)
    Next i
    
    Close #n
End Sub

Public Sub CargarArrayLluvia()
    Dim n As Integer
    Dim i As Long
    Dim Nu As Integer
    
    n = FreeFile()
    Open DataPath & "fk.ind" For Binary Access Read As #n
    
    Get #n, , MiCabecera
    
    Get #n, , Nu
    
    'Resize array
    ReDim bLluvia(1 To Nu) As Byte
    
    For i = 1 To Nu
        Get #n, , bLluvia(i)
    Next i
    
    Close #n
End Sub

Public Sub ConvertCPtoTP(ByVal viewPortX As Integer, ByVal viewPortY As Integer, ByRef tX As Byte, ByRef tY As Byte)
'Converts where the mouse is in the main window to a tile position. MUST be called eveytime the mouse moves.

    tX = UserPos.X + viewPortX / 32 - WindowTileWidth * 0.5
    tY = UserPos.Y + viewPortY / 32 - WindowTileHeight * 0.5
End Sub

Public Sub MakeChar(ByVal CharIndex As Integer, ByVal Body As Integer, ByVal Head As Integer, ByVal Heading As Byte, ByVal X As Integer, ByVal Y As Integer, Optional ByVal Arma As Integer = 0, Optional ByVal Escudo As Integer = 0, Optional ByVal Casco As Integer = 0)

On Error Resume Next

    'Apuntamos al ultimo Char
    If CharIndex > LastChar Then
        LastChar = CharIndex
    End If
    
    With Charlist(CharIndex)
        'If the char wasn't allready active (we are rewritting it) don't increase char count
        If .Active = False Then
            NumChars = NumChars + 1
        End If
        
        If Arma < 1 Then
            Arma = 2
        End If
        
        If Escudo < 1 Then
            Escudo = 2
        End If
        
        If Casco < 1 Then
            Casco = 2
        End If
        
        .iHead = Head
        .iBody = Body
        .Head = HeadData(Head)
        .Body = BodyData(Body)
        .Arma = WeaponAnimData(Arma)
        
        .Escudo = ShieldAnimData(Escudo)
        .Casco = CascoAnimData(Casco)
        
        .Heading = Heading
        
        'Reset moving stats
        .Moving = False
        .MoveOffsetX = 0
        .MoveOffsetY = 0
        
        'Update position
        .Pos.X = X
        .Pos.Y = Y
        
        'Make active
        .Active = True
    End With
    
    'Plot on map
    MapData(X, Y).CharIndex = CharIndex

End Sub

Public Sub ResetCharInfo(ByVal CharIndex As Integer)
    With Charlist(CharIndex)
        .Active = False
        .FxIndex = 0
        .Invisible = False
        .Paralizado = False
        .Moving = False
        .Nombre = vbNullString
        .Pie = 0
        .Pos.X = 0
        .Pos.Y = 0
        .Lvl = 0
        .Priv = 0
        .CompaIndex = 0
        .MascoIndex = 0
        .Quieto = False
        .EsUser = False
    End With
End Sub

Public Sub EraseChar(ByVal CharIndex As Integer)
'Erases a Char from CharList and map

On Error Resume Next
    Charlist(CharIndex).Active = False

    'Update lastchar
    If CharIndex = LastChar Then
        Do Until Charlist(LastChar).Active = True
            LastChar = LastChar - 1
            If LastChar = 0 Then
                Exit Do
            End If
        Loop
    End If
    
    If Charlist(CharIndex).Pos.X > 0 And Charlist(CharIndex).Pos.Y > 0 Then
        MapData(Charlist(CharIndex).Pos.X, Charlist(CharIndex).Pos.Y).CharIndex = 0
    End If
    
    'Remove char's dialog
    Call Dialogos.RemoveDialog(CharIndex)
    
    Call ResetCharInfo(CharIndex)
    
    If AttackedCharIndex = CharIndex Then
        AttackedCharIndex = 0
        CharMinHP = 0
    End If
    
    If AttackerCharIndex = CharIndex Then
        AttackerCharIndex = 0
        CharDamage2 = vbNullString
        DamageType = 1
    End If
    
    'Update NumChars
    NumChars = NumChars - 1

End Sub

Public Sub InitGrh(ByRef Grh As Grh, ByVal GrhIndex As Integer, Optional ByVal Started As Byte = 2)
'Sets up a grh. MUST be done before rendering
    Grh.GrhIndex = GrhIndex
    
    If Grh.GrhIndex < 1 Or Grh.GrhIndex > 32000 Then
        Exit Sub
    End If
    
    If Started = 2 Then
        If GrhData(Grh.GrhIndex).NumFrames > 1 Then
            Grh.Started = 1
        Else
            Grh.Started = 0
        End If
    Else
        'Make sure the graphic can be started
        If GrhData(Grh.GrhIndex).NumFrames = 1 Then
            Started = 0
        End If
        
        Grh.Started = Started
    End If
    
    If Grh.Started Then
        Grh.Loops = INFINITE_LOOPS
    Else
        Grh.Loops = 0
    End If
    
    Grh.FrameCounter = 1
    Grh.Speed = GrhData(Grh.GrhIndex).Speed * 1.3
End Sub

Public Sub MoveCharbyHead(ByVal nHeading As eHeading)
'Starts the movement of a Char in nHeading direction

On Error Resume Next

    If UserCharIndex < 1 Then
        Exit Sub
    End If
    
    Dim addX As Integer
    Dim addY As Integer
    Dim X As Integer
    Dim Y As Integer
    Dim nX As Integer
    Dim nY As Integer
    
    With Charlist(UserCharIndex)
        X = .Pos.X
        Y = .Pos.Y
        
        'Figure out which way to move
        Select Case nHeading
            Case eHeading.NORTH
                addY = -1
        
            Case eHeading.EAST
                addX = 1
        
            Case eHeading.SOUTH
                addY = 1
            
            Case eHeading.WEST
                addX = -1
        End Select
        
        nX = X + addX
        nY = Y + addY
        
        If nY < MinLimiteY Or nY > MaxLimiteY Or nX < MinLimiteX Or nX > MaxLimiteX Then
            Exit Sub
        End If
        
        MapData(nX, nY).CharIndex = UserCharIndex
        .Pos.X = nX
        .Pos.Y = nY
        MapData(X, Y).CharIndex = 0
        
        .MoveOffsetX = -32 * addX
        .MoveOffsetY = -32 * addY
        
        .Moving = True
        .Heading = nHeading
        
        .ScrollDirectionX = addX
        .ScrollDirectionY = addY
    End With
    
    Call MoveScreen(nHeading)

    Call DoPasosFx(UserCharIndex)

    Call DibujarMiniMapa

End Sub

Public Sub DoPortalFx()
    Dim location As Position
    
    If bPortal Then
        bPortal = HayPortal(location)
        If Not bPortal Then
            Call Audio.mSound_StopWav(PortalBufferIndex)
            PortalBufferIndex = 0
        End If
    Else
        bPortal = HayPortal(location)
        If bPortal And PortalBufferIndex = 0 Then
            PortalBufferIndex = Audio.mSound_PlayWav(SND_PORTAL, 1)
        End If
    End If
End Sub

Public Sub DoFogataFx()
    Dim location As Position
    
    If bFogata Then
        bFogata = HayFogata(location)
        If Not bFogata Then
            Call Audio.mSound_StopWav(FogataBufferIndex)
            FogataBufferIndex = 0
        End If
    Else
        bFogata = HayFogata(location)
        If bFogata And FogataBufferIndex = 0 Then
            FogataBufferIndex = Audio.mSound_PlayWav(SND_FOGATA, 1)
        End If
    End If
End Sub

Private Function EstaPCarea(ByVal CharIndex As Integer) As Boolean
    With Charlist(CharIndex).Pos
        EstaPCarea = .X > UserPos.X - MinXBorder And .X < UserPos.X + MinXBorder And .Y > UserPos.Y - MinYBorder And .Y < UserPos.Y + MinYBorder
    End With
End Function

Public Sub DoPasosFx(ByVal CharIndex As Integer)
    
    With Charlist(CharIndex)
        
        If .Priv > 1 And UserCharIndex <> CharIndex Then
            Exit Sub
        End If
    
        If EstaPCarea(CharIndex) And .iHead <> CASPER_HEAD And .iBody <> FRAGATA_FANTASMAL Then
    
            If Not UserNavegando Then
                .Pie = Not .Pie
                
                If .Pie Then
                    Call Audio.mSound_PlayWav(SND_PASOS1)
                Else
                    Call Audio.mSound_PlayWav(SND_PASOS2)
                End If
            Else
                Call Audio.mSound_PlayWav(SND_NAVEGANDO)
            End If
            
        End If
    End With
End Sub

Public Sub MoveCharbyPos(ByVal CharIndex As Integer, ByVal nX As Integer, ByVal nY As Integer)
    
On Error Resume Next

    If UserCharIndex < 1 Then
        Exit Sub
    End If
    
    If CharIndex = UserCharIndex Then
        If UserParalizado Then
            Exit Sub
        End If
    End If
    
    Dim X As Integer
    Dim Y As Integer
    Dim addX As Integer
    Dim addY As Integer
    Dim nHeading As eHeading
    
    With Charlist(CharIndex)
        X = .Pos.X
        Y = .Pos.Y
        
        If X < 1 Or Y < 1 Then
            Exit Sub
        End If
                        
        addX = nX - X
        addY = nY - Y
        
        If Sgn(addX) = 1 Then
            nHeading = eHeading.EAST
        ElseIf Sgn(addX) = -1 Then
            nHeading = eHeading.WEST
        ElseIf Sgn(addY) = -1 Then
            nHeading = eHeading.NORTH
        ElseIf Sgn(addY) = 1 Then
            nHeading = eHeading.SOUTH
        End If

        If MapData(nX, nY).CharIndex = UserCharIndex Then
            With Charlist(UserCharIndex)
                Charlist(UserCharIndex).Pos = PrevUserPos
                MapData(.Pos.X, .Pos.Y).CharIndex = UserCharIndex
                UserPos = PrevUserPos
            End With
        End If

        MapData(X, Y).CharIndex = 0

        MapData(nX, nY).CharIndex = CharIndex
                
        .Pos.X = nX
        .Pos.Y = nY
        
        .MoveOffsetX = -1 * (32 * addX)
        .MoveOffsetY = -1 * (32 * addY)
        
        .Moving = True
        .Heading = nHeading
        
        .ScrollDirectionX = Sgn(addX)
        .ScrollDirectionY = Sgn(addY)
    End With
    
    If Not EstaPCarea(CharIndex) Then
        Call Dialogos.RemoveDialog(CharIndex)
    End If
    
    If nY < MinLimiteY Or nY > MaxLimiteY Or nX < MinLimiteX Or nX > MaxLimiteX Then
        CharIndex = 0
        'Call EraseChar(CharIndex)
    End If
    
    Call DibujarMiniMapa

End Sub

Public Sub MoveScreen(ByVal nHeading As eHeading)
'Starts the screen moving in a direction

On Error GoTo Error

    Dim X As Integer
    Dim Y As Integer
    Dim tX As Integer
    Dim tY As Integer
    
    'Figure out which way to move
    Select Case nHeading
        Case eHeading.NORTH
            Y = -1
        
        Case eHeading.EAST
            X = 1
        
        Case eHeading.SOUTH
            Y = 1
        
        Case eHeading.WEST
            X = -1
    End Select
    
    'Fill temp pos
    tX = UserPos.X + X
    tY = UserPos.Y + Y
    
    'Check to see if its out of bounds
    If tX < MinXBorder Or tX > MaxXBorder Or tY < MinYBorder Or tY > MaxYBorder Then
        Exit Sub
    Else
        PrevUserPos = UserPos

        'Start moving... MainLoop does the rest
        AddtoUserPos.X = X
        UserPos.X = tX
        AddtoUserPos.Y = Y
        UserPos.Y = tY
        UserMoving = True
        
        bTecho = IIf(MapData(UserPos.X, UserPos.Y).Trigger = 1 Or _
            MapData(UserPos.X, UserPos.Y).Trigger = 2 Or _
            MapData(UserPos.X, UserPos.Y).Trigger = 4, True, False)
    End If
    
    Exit Sub
Error: MsgBox Err.Description
End Sub

Private Function HayPortal(ByRef location As Position) As Boolean
    Dim j As Long
    Dim k As Long
    
    For j = UserPos.X - 8 To UserPos.X + 8
        For k = UserPos.Y - 6 To UserPos.Y + 6
            If InMapBounds(j, k) Then
                If MapData(j, k).Obj.Grh.GrhIndex = GrhPortal Then
                    location.X = j
                    location.Y = k
                    
                    HayPortal = True
                    Exit Function
                End If
            End If
        Next k
    Next j
End Function

Private Function HayFogata(ByRef location As Position) As Boolean
    Dim j As Long
    Dim k As Long
    
    For j = UserPos.X - 8 To UserPos.X + 8
        For k = UserPos.Y - 6 To UserPos.Y + 6
            If InMapBounds(j, k) Then
                If MapData(j, k).Obj.Grh.GrhIndex = GrhFogata Then
                    location.X = j
                    location.Y = k
                    
                    HayFogata = True
                    Exit Function
                End If
            End If
        Next k
    Next j
End Function

Public Function NextOpenChar() As Integer
'Finds next open char Slot in CharList

    Dim loopc As Long
    Dim Dale As Boolean
    
    loopc = 1
    Do While Charlist(loopc).Active And Dale
        loopc = loopc + 1
        Dale = (loopc <= UBound(Charlist))
    Loop
    
    NextOpenChar = loopc
End Function

Private Function LoadGrhData() As Boolean

On Error GoTo ErrorHandler

    Dim Grh As Long
    Dim Frame As Long
    Dim grhCount As Long
    Dim handle As Integer
    Dim fileVersion As Long
    
    'Open files
    handle = FreeFile()
    
    Open DataPath & GrhFile For Binary Access Read As handle
    Seek #1, 1
    
    'Get file version
    Get handle, , fileVersion
    
    'Get number of grhs
    Get handle, , grhCount
    
    'Resize arrays
    ReDim GrhData(1 To grhCount) As GrhData
    
    While Not EOF(handle)
        Get handle, , Grh
        
        If Grh = 0 Then
            Grh = 1
        End If
        
        With GrhData(Grh)
            'Get number of frames
            Get handle, , .NumFrames
            
            If .NumFrames <= 0 Then
                GoTo ErrorHandler
            End If
            
            ReDim .Frames(1 To GrhData(Grh).NumFrames)
            
            If .NumFrames > 1 Then
                'Read a animation GRH set
                For Frame = 1 To .NumFrames
                    Get handle, , .Frames(Frame)
                    If .Frames(Frame) <= 0 Or .Frames(Frame) > grhCount Then
                        GoTo ErrorHandler
                    End If
                Next Frame
                
                Get handle, , .Speed
                
                If .Speed <= 0 Then
                    GoTo ErrorHandler
                End If
                
                'Compute width and height
                .PixelHeight = GrhData(.Frames(1)).PixelHeight
                
                If .PixelHeight <= 0 Then
                    GoTo ErrorHandler
                End If
                
                .PixelWidth = GrhData(.Frames(1)).PixelWidth
                
                If .PixelWidth <= 0 Then
                    GoTo ErrorHandler
                End If
                
                .TileWidth = GrhData(.Frames(1)).TileWidth
                
                If .TileWidth <= 0 Then
                    GoTo ErrorHandler
                End If
                
                .TileHeight = GrhData(.Frames(1)).TileHeight
                
                If .TileHeight <= 0 Then
                    GoTo ErrorHandler
                End If
                
            Else
                'Read in normal GRH data
                Get handle, , .FileNum
                
                If .FileNum <= 0 Then
                    GoTo ErrorHandler
                End If
                
                Get handle, , GrhData(Grh).sX
                
                If .sX < 0 Then
                    GoTo ErrorHandler
                End If
                
                Get handle, , .sY
                
                If .sY < 0 Then
                    GoTo ErrorHandler
                End If
                
                Get handle, , .PixelWidth
                
                If .PixelWidth <= 0 Then
                    GoTo ErrorHandler
                End If
                
                Get handle, , .PixelHeight
                
                If .PixelHeight <= 0 Then
                    GoTo ErrorHandler
                End If
                
                'Compute width and height
                .TileWidth = .PixelWidth / 32
                .TileHeight = .PixelHeight / 32
                
                .Frames(1) = Grh
            End If
        End With
    Wend
    
    Close handle
        
    LoadGrhData = True
Exit Function

ErrorHandler:
    LoadGrhData = False
End Function

Public Function LegalPos(ByVal X As Integer, ByVal Y As Integer) As Boolean
'Checks to see if a tile position is legal

    'Limites del mapa
    If X < MinXBorder Or X > MaxXBorder Or Y < MinYBorder Or Y > MaxYBorder Then
        Exit Function
    End If
    
    'Tile Bloqueado?
    If MapData(X, Y).Blocked Then
        Exit Function
    End If
    
    '�Hay un personaje?
    If MapData(X, Y).CharIndex > 0 Then
        Exit Function
    End If
    
    If UserNavegando <> HayAgua(X, Y) Then
        Exit Function
    End If
    
    LegalPos = True
End Function

Public Function MoveToLegalPos(ByVal Direccion As Byte) As Boolean
'Checks to see if a tile position is legal, including if there is a casper in the tile

    Dim X As Byte, Y As Byte
    Dim CharIndex As Integer
    
    Select Case Direccion
        Case eHeading.NORTH
            X = UserPos.X
            Y = UserPos.Y - 1
        Case eHeading.EAST
            X = UserPos.X + 1
            Y = UserPos.Y
        Case eHeading.SOUTH
            X = UserPos.X
            Y = UserPos.Y + 1
        Case eHeading.WEST
            X = UserPos.X - 1
            Y = UserPos.Y
    End Select
    
    'Limites del mapa
    If X < MinXBorder Or X > MaxXBorder Or Y < MinYBorder Or Y > MaxYBorder Then
        Exit Function
    End If
    
    'Tile Bloqueado?
    If MapData(X, Y).Blocked Then
        If Charlist(UserCharIndex).Priv < 2 Then
            Exit Function
        End If
    End If
    
    CharIndex = MapData(X, Y).CharIndex
    
    '�Hay un personaje?
    If CharIndex > 0 Then
    
        If MapData(UserPos.X, UserPos.Y).Blocked Then
            Exit Function
        End If
        
        With Charlist(CharIndex)
            'Si no es casper, no puede pasar
            If .iHead <> CASPER_HEAD And .iBody <> FRAGATA_FANTASMAL Then
                Exit Function
            Else
                If HayAgua(UserPos.X, UserPos.Y) Then
                    If Not HayAgua(X, Y) Then
                        Exit Function
                    End If
                ElseIf HayAgua(X, Y) Then
                    Exit Function
                End If
                
                'Los admins no pueden intercambiar pos con caspers cuando estan invisibles
                If Charlist(UserCharIndex).Priv > 1 Then
                    If Charlist(UserCharIndex).Invisible Then
                        Exit Function
                    End If
                End If
            End If
        End With
    End If
      
    If UserNavegando <> HayAgua(X, Y) Then
        If Charlist(UserCharIndex).Priv < 2 Then
            Exit Function
        End If
    End If
    
    MoveToLegalPos = True
End Function

Public Function InMapBounds(ByVal X As Integer, ByVal Y As Integer) As Boolean
'Checks to see if a tile position is in the maps bounds

    If X < 1 Or X > 100 Or Y < 1 Or Y > 100 Then
        Exit Function
    End If
    
    InMapBounds = True
End Function

Private Sub DDrawGrhtoSurface(ByRef Grh As Grh, ByVal X As Integer, ByVal Y As Integer, ByVal Center As Byte, ByVal Animate As Byte)
    Dim CurrentGrhIndex As Integer

On Error GoTo Error
    
    If Grh.GrhIndex < 1 Then
        Exit Sub
    End If

    If Animate Then
        If Grh.Started = 1 Then
            Grh.FrameCounter = Grh.FrameCounter + (timerElapsedTime * GrhData(Grh.GrhIndex).NumFrames / Grh.Speed)
            If Grh.FrameCounter > GrhData(Grh.GrhIndex).NumFrames Then
                Grh.FrameCounter = (Grh.FrameCounter Mod GrhData(Grh.GrhIndex).NumFrames) + 1
                
                If Grh.Loops <> INFINITE_LOOPS Then
                    If Grh.Loops > 0 Then
                        Grh.Loops = Grh.Loops - 1
                    Else
                        Grh.Started = 0
                    End If
                End If
            End If
        End If
    End If
     
    'Figure out what frame to draw (always 1 if not animated)
    CurrentGrhIndex = GrhData(Grh.GrhIndex).Frames(Grh.FrameCounter)
    
    With GrhData(CurrentGrhIndex)
        'Center Grh over X,Y pos
        If Center Then
            If .TileWidth <> 1 Then
                X = X - Int(.TileWidth * 32 * 0.5) + 32 * 0.5
            End If
            
            If .TileHeight <> 1 Then
                Y = Y - Int(.TileHeight * 32) + 32
            End If
        End If
        
        Call modDX8_Draw.Draw_Quad(.FileNum, X, Y, .PixelWidth, .PixelHeight, .sX, .sY, sDefaultColor)
    End With
Exit Sub

Error:
    If Err.Number = 9 And Grh.FrameCounter < 1 Then
        Grh.FrameCounter = 1
        Resume
    Else
        MsgBox "Ocurri� un Error inesperado, por favor comuniquelo a los administradores del juego." & vbCrLf & "Descripci�n del Error: " & _
        vbCrLf & Err.Description, vbExclamation, "[ " & Err.Number & " ] Error"
        End
    End If
End Sub

Public Sub DDrawTransGrhIndextoSurface(ByVal GrhIndex As Integer, ByVal X As Integer, ByVal Y As Integer, ByVal Center As Byte)
    With GrhData(GrhIndex)
        'Center Grh over X,Y pos
        If Center Then
            If .TileWidth <> 1 Then
                X = X - Int(.TileWidth * 32 * 0.5) + 32 * 0.5
            End If
            
            If .TileHeight <> 1 Then
                Y = Y - Int(.TileHeight * 32) + 32
            End If
        End If
        
        Call modDX8_Draw.Draw_Quad(.FileNum, X, Y, .PixelWidth, .PixelHeight, .sX, .sY, sDefaultColor)
    End With
End Sub

Public Sub DDrawTransGrhtoSurface(ByRef Grh As Grh, ByVal X As Integer, ByVal Y As Integer, ByVal Center As Byte, ByVal Animate As Byte)
'Draws a GRH transparently to a X and Y position

    Dim CurrentGrhIndex As Integer
    
On Error GoTo Error
    
    If Animate Then
        If Grh.Started = 1 Then
            Grh.FrameCounter = Grh.FrameCounter + (timerElapsedTime * GrhData(Grh.GrhIndex).NumFrames / Grh.Speed)
            
            If Grh.FrameCounter > GrhData(Grh.GrhIndex).NumFrames Then
                Grh.FrameCounter = (Grh.FrameCounter Mod GrhData(Grh.GrhIndex).NumFrames) + 1
                
                If Grh.Loops <> INFINITE_LOOPS Then
                    If Grh.Loops > 0 Then
                        Grh.Loops = Grh.Loops - 1
                    Else
                        Grh.Started = 0
                    End If
                End If
            End If
        End If
    End If
    
    'Figure out what frame to draw (always 1 if not animated)
    CurrentGrhIndex = GrhData(Grh.GrhIndex).Frames(Grh.FrameCounter)
    
    With GrhData(CurrentGrhIndex)
        'Center Grh over X,Y pos
        If Center Then
            If .TileWidth <> 1 Then
                X = X - Int(.TileWidth * 32 * 0.5) + 32 * 0.5
            End If
            
            If .TileHeight <> 1 Then
                Y = Y - Int(.TileHeight * 32) + 32
            End If
        End If
                

        Call modDX8_Draw.Draw_Quad(.FileNum, X, Y, .PixelWidth, .PixelHeight, .sX, .sY, sDefaultColor)
    End With
Exit Sub

Error:

    Exit Sub
    
    If Err.Number = 9 And Grh.FrameCounter < 1 Then
        Grh.FrameCounter = 1
        Resume
    Else
        MsgBox "Ocurri� un Error inesperado, por favor comuniquelo a los administradores del juego." & vbCrLf & "Descripci�n del Error: " & _
        vbCrLf & Err.Description, vbExclamation, "[ " & Err.Number & " ] Error"
        End
    End If
End Sub

Public Sub DDrawTransGrhtoSurfaceAlpha(ByRef Grh As Grh, ByVal X As Integer, ByVal Y As Integer, ByVal Center As Byte, ByVal Animate As Byte)
'Draws a GRH transparently to a X and Y position

On Error Resume Next
    
    Dim CurrentGrhIndex As Integer
 
    If Animate Then
        If Grh.Started = 1 Then
            Grh.FrameCounter = Grh.FrameCounter + (timerElapsedTime * GrhData(Grh.GrhIndex).NumFrames / Grh.Speed)
            
            If Grh.FrameCounter > GrhData(Grh.GrhIndex).NumFrames Then
                Grh.FrameCounter = (Grh.FrameCounter Mod GrhData(Grh.GrhIndex).NumFrames) + 1
                
                If Grh.Loops <> INFINITE_LOOPS Then
                    If Grh.Loops > 0 Then
                        Grh.Loops = Grh.Loops - 1
                    Else
                        Grh.Started = 0
                    End If
                End If
            End If
        End If
    End If
    
    'Figure out what frame to draw (always 1 if not animated)
    CurrentGrhIndex = GrhData(Grh.GrhIndex).Frames(Grh.FrameCounter)
    
    With GrhData(CurrentGrhIndex)
        'Center Grh over X,Y pos
        If Center Then
            If .TileWidth <> 1 Then
                X = X - Int(.TileWidth * 32 * 0.5) + 32 * 0.5
            End If
            If .TileHeight <> 1 Then
                Y = Y - Int(.TileHeight * 32) + 32
            End If
        End If
        
        Call modDX8_Draw.Draw_Quad(.FileNum, X, Y, .PixelWidth, .PixelHeight, .sX, .sY, sAlphaColor)
    End With

End Sub

Public Sub DrawGrhtoHdc(ByVal hdc As Long, ByVal GrhIndex As Integer, ByRef SourceRect As RECT, ByRef DestRect As RECT)
    'Draws a Grh's portion to the given area of any Device Context
    'Terminar!Lea
    'Call SurfaceDB.Surface(GrhData(GrhIndex).FileNum).BltToDC(hdc, SourceRect, DestRect)
End Sub

Public Sub DrawTransparentGrhtoHdc(ByVal dsthdc As Long, ByVal dstX As Long, ByVal dstY As Long, ByVal GrhIndex As Integer, ByRef SourceRect As RECT)
''This method is SLOW... Don't use in a loop if you care about
''speed!
'    Dim color As Long
'    Dim X As Long
'    Dim Y As Long
'    Dim srchdc As Long
'
'    Set Surface = SurfaceDB.Surface(GrhData(GrhIndex).FileNum)
'
'    srchdc = Surface.GetDC
'
'    For X = SourceRect.Left To SourceRect.Right - 1
'        For Y = SourceRect.Top To SourceRect.bottom - 1
'            color = GetPixel(srchdc, X, Y)
'
'            If color <> vbBlack Then
'                Call SetPixel(dsthdc, dstX + (X - SourceRect.Left), dstY + (Y - SourceRect.Top), color)
'            End If
'        Next Y
'    Next X
'
'    Call Surface.ReleaseDC(srchdc)
'Terminar!Lea
End Sub

Public Sub DrawImageInPicture(ByRef PictureBox As PictureBox, ByRef Picture As StdPicture, ByVal X1 As Single, ByVal Y1 As Single, Optional Width1, Optional Height1, Optional X2, Optional Y2, Optional Width2, Optional Height2)
'Draw Picture in the PictureBox
    Call PictureBox.PaintPicture(Picture, X1, Y1, Width1, Height1, X2, Y2, Width2, Height2)
End Sub

Public Sub RenderScreen(ByVal TileX As Integer, ByVal TileY As Integer, ByVal PixelOffsetX As Integer, ByVal PixelOffsetY As Integer)
'Renders everything to the viewport
    
    On Error Resume Next
    
    Dim X           As Integer     'Keeps track of where on map we are
    Dim Y           As Integer     'Keeps track of where on map we are
    Dim ScreenMinX  As Integer  'Start Y pos on current screen
    Dim ScreenMaxX  As Integer  'End Y pos on current screen
    Dim ScreenMinY  As Integer  'Start X pos on current screen
    Dim ScreenMaxY  As Integer  'End X pos on current screen
    Dim MinX       As Integer  'Start Y pos on current map
    Dim MaxX        As Integer  'End Y pos on current map
    Dim MinY        As Integer  'Start X pos on current map
    Dim MaxY        As Integer  'End X pos on current map
    Dim ScreenX     As Integer  'Keeps track of where to place tile on screen
    Dim ScreenY     As Integer  'Keeps track of where to place tile on screen
    Dim minXOffset  As Integer
    Dim minYOffset  As Integer
    Dim PixelOffsetXTemp As Integer 'For centering grhs
    Dim PixelOffsetYTemp As Integer 'For centering grhs
    
    'Figure out Ends and Starts of screen

    ScreenMinX = TileX - HalfWindowTileWidth
    ScreenMaxX = TileX + HalfWindowTileWidth
    ScreenMinY = TileY - HalfWindowTileHeight
    ScreenMaxY = TileY + HalfWindowTileHeight
        
    MinX = ScreenMinX - 9 'TileBufferSize
    MaxX = ScreenMaxX + 9 'TileBufferSize
    MinY = ScreenMinY - 9 'TileBufferSize
    MaxY = ScreenMaxY + 9 'TileBufferSize

    ScreenMinX = ScreenMinX - 1
    ScreenMaxX = ScreenMaxX + 1
    ScreenMinY = ScreenMinY - 1
    ScreenMaxY = ScreenMaxY + 1

    'Draw floor layer
    For Y = ScreenMinY To ScreenMaxY
        For X = ScreenMinX To ScreenMaxX
            If InMapBounds(X, Y) Then
                'Layer 1
                If MapData(X, Y).Graphic(1).GrhIndex > 1 Then
                    Call DDrawGrhtoSurface(MapData(X, Y).Graphic(1), _
                        (ScreenX - 1) * 32 + PixelOffsetX + TileBufferPixelOffsetX, _
                        (ScreenY - 1) * 32 + PixelOffsetY + TileBufferPixelOffsetY, _
                        0, 1)
                End If
            End If
                
            ScreenX = ScreenX + 1
        Next X
        
        'Reset ScreenX to original value and increment ScreenY
        ScreenX = ScreenX - X + ScreenMinX
        ScreenY = ScreenY + 1
    Next Y
    
    'Draw floor layer 2
    ScreenY = minYOffset
    
    For Y = MinY To MaxY
        ScreenX = minXOffset
        For X = MinX To MaxX
            If InMapBounds(X, Y) Then
            
                'Layer 2
                If MapData(X, Y).Graphic(2).GrhIndex > 1 Then
                    Call DDrawTransGrhtoSurface(MapData(X, Y).Graphic(2), _
                        (ScreenX - 1) * 32 + PixelOffsetX, _
                        (ScreenY - 1) * 32 + PixelOffsetY, _
                        1, 1)
                End If
            End If
            
            ScreenX = ScreenX + 1
        Next X
        ScreenY = ScreenY + 1
    Next Y
    
    'Draw Transparent Layers
    ScreenY = minYOffset
    
    For Y = MinY To MaxY
        ScreenX = minXOffset
        For X = MinX To MaxX
            If InMapBounds(X, Y) Then
                PixelOffsetXTemp = (ScreenX - 1) * 32 + PixelOffsetX
                PixelOffsetYTemp = (ScreenY - 1) * 32 + PixelOffsetY
                
                With MapData(X, Y)
    
                    'Object Layer
                    If .Obj.Grh.GrhIndex > 0 Then
                    
                        If AlphaBActivated Then
                            If .Obj.Grh.GrhIndex = GrhPortal Or _
                            (.Obj.ObjType = otPuerta And Charlist(UserCharIndex).Priv > 1) Then
                                Call DDrawTransGrhtoSurfaceAlpha(.Obj.Grh, PixelOffsetXTemp, PixelOffsetYTemp, 1, 1)
                            Else
                                Call DDrawTransGrhtoSurface(.Obj.Grh, PixelOffsetXTemp, PixelOffsetYTemp, 1, 1)
                            End If
                        Else
                            Call DDrawTransGrhtoSurface(.Obj.Grh, PixelOffsetXTemp, PixelOffsetYTemp, 1, 1)
                        End If
    
                        If MouseTileX = X Then
                            If MouseTileY = Y Then
                            
                                If MouseTileX > 9 And MouseTileX < 92 And MouseTileY > 7 And MouseTileY < 94 Then
                            
                                    If .Obj.Amount > 0 Then
                                    
                                        Call InitObjName(.Obj.Name, .Obj.ObjType, PixelOffsetXTemp + 30, PixelOffsetYTemp - 10)
                                        
                                        If AlphaBActivated Then
                                            Call SurfaceColor(.Obj.Grh, PixelOffsetXTemp, PixelOffsetYTemp, 225, 225, 50)
                                        End If
                                        
                                        If UsingSkill = 0 Then
                                            If X = UserPos.X And Y = UserPos.Y Then
                                                frmMain.MousePointer = 5
                                            End If
                                        End If
                                        
                                    ElseIf .Obj.ObjType = otCuerpoMuerto Then
                                        Call InitObjName(.Obj.Name, .Obj.ObjType, PixelOffsetXTemp + 30, PixelOffsetYTemp - 10)
                                        
                                        If AlphaBActivated Then
                                            Call SurfaceColor(.Obj.Grh, PixelOffsetXTemp, PixelOffsetYTemp, 225, 225, 50)
                                        End If
                                    
                                    ElseIf .Obj.ObjType = otTeleport Then
                                        Call InitObjName(.Obj.Name, .Obj.ObjType, PixelOffsetXTemp + 30, PixelOffsetYTemp - 10)
                                
                                        If AlphaBActivated Then
                                            'If .Obj.Grh.Started = 2 Then
                                                Call SurfaceColor(.Obj.Grh, PixelOffsetXTemp, PixelOffsetYTemp, 225, 225, 50)
                                            'End If
                                        End If
                                    Else
                                        Call RemoveObjName
                                    End If
                                Else
                                    Call RemoveObjName
                                End If
                            End If
                        End If
                    Else
                        If MouseTileX = X And MouseTileY = Y Then
                            Call RemoveObjName
                            
                            If UsingSkill = 0 Then
                                frmMain.MousePointer = vbDefault
                            End If
                        End If
                    End If
                    
                    'Char layer
                    If .CharIndex > 0 Then
                        If Charlist(.CharIndex).Pos.X <> X Or Charlist(.CharIndex).Pos.Y <> Y Then
                            .CharIndex = 0
                            'Call EraseChar(.CharIndex)
                            
                        Else
                            Call CharRender(.CharIndex, PixelOffsetXTemp, PixelOffsetYTemp)
                            
                            If MouseTileX = X Then
                                If MouseTileY = Y Then
                                    If .CharIndex <> UserCharIndex Then
                                        If Charlist(.CharIndex).EsUser Then
                                            If Not Charlist(.CharIndex).Invisible Then
                                                If Charlist(.CharIndex).Priv < 2 Then
                                                    Call InitCharName(.CharIndex)
                                                End If
                                            End If
                                        Else
                                            Call InitCharName(.CharIndex)
                                        End If
                                    End If
                                End If
                            End If
                        End If
                    ElseIf MouseTileX = X And MouseTileY = Y Then
                        Call RemoveCharName
                    End If
                    
                    'Layer 3 *
                    If .Graphic(3).GrhIndex > 0 Then
                        If X > MinX And Y > MinY And X < MaxX And Y < MaxY Then
                            'Draw
                            If AlphaBActivated Then
                            
                                If Charlist(UserCharIndex).Priv > 1 Then
                                    Call DDrawTransGrhtoSurfaceAlpha(.Graphic(3), _
                                        PixelOffsetXTemp, PixelOffsetYTemp, 1, 1)
                                
                                ElseIf .Blocked And .CharIndex > 0 Then
                                    Call DDrawTransGrhtoSurfaceAlpha(.Graphic(3), _
                                        PixelOffsetXTemp, PixelOffsetYTemp, 1, 1)
                                
                                ElseIf GrhData(.Graphic(3).GrhIndex).FileNum > 5999 And GrhData(.Graphic(3).GrhIndex).FileNum < 6999 Then
                                    If (Abs(UserPos.X - X) < 3 And Abs(UserPos.X - X) >= 0 And _
                                        UserPos.Y - Y < 0 And UserPos.Y - Y > -6) Or _
                                        Charlist(UserCharIndex).Priv > 1 Then
                                        'Abs(MouseTileX - X) < 3 And
                                        'MouseTileY - Y < 0 And MouseTileY - Y > -6)
                                        
                                        Call DDrawTransGrhtoSurfaceAlpha(.Graphic(3), _
                                            PixelOffsetXTemp, PixelOffsetYTemp, 1, 1)
                                    Else
                                        Call DDrawTransGrhtoSurface(.Graphic(3), _
                                            PixelOffsetXTemp, PixelOffsetYTemp, 1, 1)
                                    End If
                                
                                ElseIf X = MouseTileX Then
                                
                                    If Y = MouseTileY Then
                                        'If MapData(X, Y).CharIndex > 0 Then
                                        'If Not Charlist(MapData(X, Y).CharIndex).Invisible Then
                                        'Call DDrawTransGrhtoSurfaceAlpha(.Graphic(3), _
                                        'PixelOffsetXTemp, PixelOffsetYTemp, 1, 1)
                                        'End If
                                            
                                        'ElseIf MapData(X, Y).Amount > 0 Or MapData(X - 1, Y).Amount > 0 Or MapData(X - 2, Y).Amount > 0 Then
                                        'Call DDrawTransGrhtoSurfaceAlpha(.Graphic(3), _
                                        'PixelOffsetXTemp, PixelOffsetYTemp, 1, 1)
                                        'Else
                                            Call DDrawTransGrhtoSurface(.Graphic(3), _
                                                PixelOffsetXTemp, PixelOffsetYTemp, 1, 1)
                                        'End If
                                    Else
                                        Call DDrawTransGrhtoSurface(.Graphic(3), _
                                            PixelOffsetXTemp, PixelOffsetYTemp, 1, 1)
                                    End If
                                    
                                Else
                                    Call DDrawTransGrhtoSurface(.Graphic(3), _
                                        PixelOffsetXTemp, PixelOffsetYTemp, 1, 1)
                                End If
                                
                            Else
                                Call DDrawTransGrhtoSurface(.Graphic(3), _
                                    PixelOffsetXTemp, PixelOffsetYTemp, 1, 1)
                            End If
                        End If
                    End If
                    
                    If .FxIndex > 0 Then
                        If AlphaBActivated Then
                            Call DDrawTransGrhtoSurfaceAlpha(.fX, PixelOffsetXTemp + FxData(.FxIndex).OffsetX, PixelOffsetYTemp + FxData(.FxIndex).OffsetY, 1, 1)
                        Else
                            Call DDrawTransGrhtoSurface(.fX, PixelOffsetXTemp + FxData(.FxIndex).OffsetX, PixelOffsetYTemp + FxData(.FxIndex).OffsetY, 1, 1)
                        End If
                        
                        'Check if animation is over
                        If .fX.Started = 0 Then
                            .FxIndex = 0
                        End If
                    End If
                    
                End With
            End If
            
            ScreenX = ScreenX + 1
        Next X
        ScreenY = ScreenY + 1
    Next Y
    
    'Draw blocked tiles and grid
    ScreenY = minYOffset
    
    For Y = MinY To MaxY
        ScreenX = minXOffset
        For X = MinX To MaxX
        
            If InMapBounds(X, Y) Then
                'Layer 4
                If MapData(X, Y).Graphic(4).GrhIndex > 0 Then
                    'Draw
                    If AlphaBActivated And Not bTecho And Charlist(UserCharIndex).Priv < 2 Then
                        Call DDrawTransGrhtoSurfaceAlpha(MapData(X, Y).Graphic(4), _
                            (ScreenX - 1) * 32 + PixelOffsetX, _
                            (ScreenY - 1) * 32 + PixelOffsetY, _
                            1, 0)
                    
                    ElseIf Not bTecho And Charlist(UserCharIndex).Priv < 2 Then
                        Call DDrawTransGrhtoSurface(MapData(X, Y).Graphic(4), _
                            (ScreenX - 1) * 32 + PixelOffsetX, _
                            (ScreenY - 1) * 32 + PixelOffsetY, _
                            1, 0)
                    End If
                End If
            End If
            
            ScreenX = ScreenX + 1
        Next X
        ScreenY = ScreenY + 1
    Next Y

'TODO : Check this!
    'If bLluvia(Map) = 1 Then
    'If bRain Then
            'Figure out what frame to draw
    'If llTick < DirectX.TickCount - 50 Then
    'iFrameIndex = iFrameIndex + 1
    'If iFrameIndex > 7 Then iFrameIndex = 0
    'llTick = DirectX.TickCount
    'End If

    'For Y = 0 To 4
    'For X = 0 To 4
    'Call BackBufferSurface.BltFast(LTLluvia(Y), LTLluvia(X), SurfaceDB.Surface(15168), RLluvia(iFrameIndex), DDBLTFAST_SRCCOLORKEY + DDBLTFAST_WAIT)
    'Next X
    'Next Y
    'End If
    'End If

End Sub

Public Function RenderSounds()
'Actualiza todos los sonidos del mapa.

On Error Resume Next

    If bLluvia(UserMap) = 1 Then
        If bRain Then
            If bTecho Then
                If frmMain.IsPlaying <> PlayLoop.plLluviain Then
                    If RainBufferIndex Then
                        Call Audio.mSound_StopWav(RainBufferIndex)
                    End If
                    
                    RainBufferIndex = Audio.mSound_PlayWav("lluviain.wav", 1)
                    frmMain.IsPlaying = PlayLoop.plLluviain
                End If
            Else
                If frmMain.IsPlaying <> PlayLoop.plLluviaout Then
                    If RainBufferIndex Then
                        Call Audio.mSound_StopWav(RainBufferIndex)
                    End If
                    
                    RainBufferIndex = Audio.mSound_PlayWav("lluviaout.wav", 1)
                    frmMain.IsPlaying = PlayLoop.plLluviaout
                End If
            End If
        End If
    End If
    
    Call DoPortalFx
    
    Call DoFogataFx
End Function

Public Sub LoadGraphics()
'Initializes the SurfaceDB and sets up the rain rects

    'Set up te rain rects
    RLluvia(0).Top = 0:      RLluvia(1).Top = 0:      RLluvia(2).Top = 0:      RLluvia(3).Top = 0
    RLluvia(0).Left = 0:     RLluvia(1).Left = 128:   RLluvia(2).Left = 256:   RLluvia(3).Left = 384
    RLluvia(0).Right = 128:  RLluvia(1).Right = 256:  RLluvia(2).Right = 384:  RLluvia(3).Right = 512
    RLluvia(0).bottom = 128: RLluvia(1).bottom = 128: RLluvia(2).bottom = 128: RLluvia(3).bottom = 128
    
    RLluvia(4).Top = 128:    RLluvia(5).Top = 128:    RLluvia(6).Top = 128:    RLluvia(7).Top = 128
    RLluvia(4).Left = 0:     RLluvia(5).Left = 128:   RLluvia(6).Left = 256:   RLluvia(7).Left = 384
    RLluvia(4).Right = 128:  RLluvia(5).Right = 256:  RLluvia(6).Right = 384:  RLluvia(7).Right = 512
    RLluvia(4).bottom = 256: RLluvia(5).bottom = 256: RLluvia(6).bottom = 256: RLluvia(7).bottom = 256
    
End Sub

Public Function InitTileEngine(ByVal setDisplayFormhWnd As Long, ByVal setMainViewTop As Integer, ByVal setMainViewLeft As Integer, ByVal setWindowTileHeight As Integer, ByVal setWindowTileWidth As Integer, ByVal setTileBufferSize As Integer, ByVal pixelsToScrollPerFrameX As Integer, pixelsToScrollPerFrameY As Integer, ByVal engineSpeed As Single) As Boolean
'Creates all DX objects and configures the engine to start running.

    'Fill startup variables
    MainViewTop = setMainViewTop
    MainViewLeft = setMainViewLeft
    WindowTileHeight = setWindowTileHeight
    WindowTileWidth = setWindowTileWidth
    TileBufferSize = setTileBufferSize
    
    HalfWindowTileHeight = setWindowTileHeight * 0.5
    HalfWindowTileWidth = setWindowTileWidth * 0.5
    
    'Compute offset in pixels when rendering tile buffer.
    'We diminish by one to get the top-left corner of the tile for rendering.
    TileBufferPixelOffsetX = ((TileBufferSize - 1) * 32)
    TileBufferPixelOffsetY = ((TileBufferSize - 1) * 32)
    
    engineBaseSpeed = engineSpeed
    
    'Set FPS value to 60 for startup
    FPS = 60
    FramesPerSecCounter = 60
    
    MinXBorder = 1 '1 + (WindowTileWidth * 0.5)
    MaxXBorder = 100 '100 - (WindowTileWidth * 0.5)
    MinYBorder = 1 '1 + (WindowTileHeight * 0.5)
    MaxYBorder = 100 '100 - (WindowTileHeight * 0.5)
    
    MainViewWidth = 32 * WindowTileWidth
    MainViewHeight = 32 * WindowTileHeight
    
    'Resize mapdata array
    ReDim MapInfo(1 To 28) As MapInfoBlock
    
    'Set intial user position
    UserPos.X = MinXBorder
    UserPos.Y = MinYBorder
    
    'Set scroll pixels per frame
    ScrollPixelsPerFrameX = pixelsToScrollPerFrameX
    ScrollPixelsPerFrameY = pixelsToScrollPerFrameY
    
    'Set the view rect
    With MainViewRect
        .Left = MainViewLeft
        .Top = MainViewTop
        .Right = .Left + MainViewWidth
        .bottom = .Top + MainViewHeight
    End With
    
    'Set the dest rect
    With MainDestRect
        .Left = 32 * TileBufferSize - 32
        .Top = 32 * TileBufferSize - 32
        .Right = .Left + MainViewWidth
        .bottom = .Top + MainViewHeight
    End With
    
On Error Resume Next

    Call LoadGrhData
    Call CargarCuerpos
    Call CargarCabezas
    Call CargarCascos
    Call CargarFxs
    
    LTLluvia(0) = 224
    LTLluvia(1) = 352
    LTLluvia(2) = 480
    LTLluvia(3) = 608
    LTLluvia(4) = 736
    
    modDX8_Draw.Device_Init frmMain.MainViewPic.hWnd, 544, 416
    
    Call LoadGraphics
    
    InitTileEngine = True
End Function

Public Sub DeinitTileEngine()
'Destroys all DX objects

On Error Resume Next
    
End Sub

Public Sub ShowNextFrame(ByVal DisplayFormTop As Integer, ByVal DisplayFormLeft As Integer, ByVal MouseViewX As Integer, ByVal MouseViewY As Integer)
'Updates the game's model and renders everything.

    Static OffsetCounterX As Single
    Static OffsetCounterY As Single
    
    'Set main view rectangle
    MainViewRect.Left = (DisplayFormLeft / Screen.TwipsPerPixelX) + MainViewLeft
    MainViewRect.Top = (DisplayFormTop / Screen.TwipsPerPixelY) + MainViewTop
    MainViewRect.Right = MainViewRect.Left + MainViewWidth
    MainViewRect.bottom = MainViewRect.Top + MainViewHeight
    
    If EngineRun Then
        If UserMoving Then
            'Move screen Left and Right if needed
            If AddtoUserPos.X <> 0 Then
                
                If UserMuerto Then
                    OffsetCounterX = OffsetCounterX - (ScrollPixelsPerFrameX + ScrollPixelsPerFrameX) * AddtoUserPos.X * timerTicksPerFrame
                Else
                    OffsetCounterX = OffsetCounterX - ScrollPixelsPerFrameX * AddtoUserPos.X * timerTicksPerFrame
                End If
                
                If Abs(OffsetCounterX) >= Abs(32 * AddtoUserPos.X) Then
                    OffsetCounterX = 0
                    AddtoUserPos.X = 0
                    UserMoving = False
                End If
            End If
            
            'Move screen Up and Down if needed
            If AddtoUserPos.Y <> 0 Then
                
                If UserMuerto Then
                    OffsetCounterY = OffsetCounterY - (ScrollPixelsPerFrameY + ScrollPixelsPerFrameY) * AddtoUserPos.Y * timerTicksPerFrame
                Else
                    OffsetCounterY = OffsetCounterY - ScrollPixelsPerFrameY * AddtoUserPos.Y * timerTicksPerFrame
                End If
                
                If Abs(OffsetCounterY) >= Abs(32 * AddtoUserPos.Y) Then
                    OffsetCounterY = 0
                    AddtoUserPos.Y = 0
                    UserMoving = False
                End If
            End If
        End If
        
        'Update mouse position within view area
        'Call ConvertCPtoTP(MouseViewX, MouseViewY, MouseTileX, MouseTileY)
        
        modDX8_Draw.Device_Render_Init
        
        'Update screen
        If Not UserCiego Then
            Call RenderScreen(UserPos.X - AddtoUserPos.X, UserPos.Y - AddtoUserPos.Y, OffsetCounterX, OffsetCounterY)
        End If
        
        'Dim con As Byte
        
        'With Consola
        'For con = 1 To 10
        'Call RenderText(260, 181 + (con * 15), .MensajeConsola(con), RGB(.Color_Red(con), .Color_Green(con), .Color_Blue(con)), frmMain.font)
        'Next con
        'End With
                
        If UserPasarNivel > 0 Then
            If frmMain.ImgExp.Width <> CInt(((UserExp * 0.01) / (UserPasarNivel * 0.01)) * 171) Then
                If frmMain.ImgExp.Width < CInt(((UserExp * 0.01) / (UserPasarNivel * 0.01)) * 171) Then
                    frmMain.ImgExp.Width = frmMain.ImgExp.Width + 1
                Else
                    If frmMain.ImgExp.Width > 1 Then
                        frmMain.ImgExp.Width = frmMain.ImgExp.Width - 2
                    Else
                        frmMain.ImgExp.Width = frmMain.ImgExp.Width - 1
                    End If
                End If
                 
                'frmMain.ExpLbl.Caption = UserExp & " / " & UserPasarNivel
            End If
        End If
                
        If UserMaxHP > 0 Then
            If frmMain.ImgHP.Width <> CInt(((UserMinHP * 0.01) / (UserMaxHP * 0.01)) * 88) Then
                If frmMain.ImgHP.Width < CInt(((UserMinHP * 0.01) / (UserMaxHP * 0.01)) * 88) Then
                    frmMain.ImgHP.Width = frmMain.ImgHP.Width + 1
                Else
                    frmMain.ImgHP.Width = frmMain.ImgHP.Width - 1
                End If
            End If
            
            frmMain.HPLbl.Caption = UserMinHP & " / " & UserMaxHP
        End If
        
        If UserMaxMan > 0 Then
            If frmMain.ImgMana.Width <> CInt(((UserMinMan * 0.01) / (UserMaxMan * 0.01)) * 88) Then
                If frmMain.ImgMana.Width < CInt(((UserMinMan * 0.01) / (UserMaxMan * 0.01)) * 88) Then
                    frmMain.ImgMana.Width = frmMain.ImgMana.Width + 1
                Else
                    frmMain.ImgMana.Width = frmMain.ImgMana.Width - 1
                End If
            End If
            
            frmMain.MANLbl.Caption = UserMinMan & " / " & UserMaxMan
        End If
        
        If UserMaxSTA > 0 Then
            If frmMain.ImgSta.Width <> CInt(((UserMinSTA * 0.01) / (UserMaxSTA * 0.01)) * 88) Then
                If frmMain.ImgSta.Width < CInt(((UserMinSTA * 0.01) / (UserMaxSTA * 0.01)) * 88) Then
                    frmMain.ImgSta.Width = frmMain.ImgSta.Width + 1
                Else
                    frmMain.ImgSta.Width = frmMain.ImgSta.Width - 1
                End If
            End If
            
            frmMain.STALbl.Caption = UserMinSTA & " / " & UserMaxSTA
        End If

        If FPSFLAG Then
            Call RenderFPS
        End If
        
        Call RenderExp
        Call RenderGld
        Call RenderDamage
        Call RenderCharHP
        Call RenderCharDamage
        Call DibujarCartel
        Call Dialogos.Render
        Call RenderObjName
        Call RenderCharName
        Call RenderCoord
        
        'FPS update
        If fpsLastCheck + 1000 < GetTickCount Then
            FPS = FramesPerSecCounter
            FramesPerSecCounter = 1
            fpsLastCheck = GetTickCount
        Else
            FramesPerSecCounter = FramesPerSecCounter + 1
        End If
                
        'Get timing info
        timerElapsedTime = GetElapsedTime()
        timerTicksPerFrame = timerElapsedTime * engineBaseSpeed
        
        modDX8_Draw.Device_Render_End
    End If
    
End Sub

Public Sub RenderText(ByVal lngXPos As Integer, ByVal lngYPos As Integer, ByRef strText As String, ByVal lngColor As Long)
    If LenB(strText) > 0 Then
        modDX8_Draw.Text_Render strText, lngXPos, lngYPos, lngColor
    End If
End Sub

Public Sub RenderTextCentered(ByVal lngXPos As Integer, ByVal lngYPos As Integer, ByRef strText As String, ByVal lngColor As Long)
    Dim hdc As Long
    Dim Ret As size
    
    If LenB(strText) > 0 Then
        modDX8_Draw.Text_Render strText, lngXPos - modDX8_Draw.Text_Width(strText) / 4, lngYPos, lngColor
    End If
End Sub

Public Sub RenderObjName()

    If LenB(ObjName) < 1 Then
        Exit Sub
    End If
    
    Dim color As Long
    
    Select Case ObjType
        Case otGuita
            color = RGB(255, 255, 200)
        
        Case otCasco, otEscudo, otArmadura, otArma, otArma
            color = RGB(230, 230, 150)
        
        Case otLlave
            color = RGB(220, 220, 100)
        
        Case otMineral, otLe�a
            color = RGB(200, 200, 0)
        
        Case otBarco
            color = RGB(200, 200, 0)
        
        Case otPergamino
            color = RGB(200, 255, 0)
        
        Case otPocion
            color = RGB(200, 200, 0)
        
        Case otBebida, otBotellaLlena, otBotellaVacia, otUseOnce
            color = RGB(150, 150, 100)
        
        Case otAnillo
            color = RGB(100, 200, 50)
                                        
        Case otTeleport
            color = RGB(200, 200, 255)
                           
        Case otCuerpoMuerto
            color = RGB(225, 225, 225)
            
    End Select
    
    RenderText ObjX, ObjY, ObjName, color
End Sub

Public Sub InitObjName(ByVal Name As String, ByVal T As eObjType, ByVal X As Integer, ByVal Y As Integer)
    
    If Name = ObjName Then
        If ObjX = X Then
            If ObjY = Y Then
                If ObjType = T Then
                    Exit Sub
                End If
            End If
        End If
    End If
    
    ObjName = Name
    ObjType = T
    ObjX = X
    ObjY = Y
End Sub

Public Sub RemoveObjName()
    If LenB(ObjName) > 0 Then
        ObjName = vbNullString
    End If
End Sub

Public Sub RenderCharName()

    If LenB(CharName) < 1 Then
        Exit Sub
    End If
    
    Dim X As Integer
    Dim Y As Integer
    
    X = 260
    Y = 260
    
    RenderText X, Y, CharName, CharColor
End Sub

Public Sub InitCharName(ByVal CharIndex As Integer)

    With Charlist(CharIndex)
    
        CharName = .Nombre
            
        If .EsUser Then
            If .Priv < 2 Then
                CharColor = RGB(230 - .Lvl, 230 - .Lvl, 100)
            Else
                CharColor = RGB(120, 210, 0)
            End If
            
            CharName = .Nombre
        
            If .Priv < 2 Then
                CharName = CharName & " (Nv. " & .Lvl & ")"
            End If
        
        Else
            Select Case .Lvl
                Case 1
                    Exit Sub
                Case 2
                    CharColor = RGB(200, 150, 85)
                Case 3
                    CharColor = RGB(200, 150, 85)
                Case 4
                    CharColor = RGB(200, 150, 85)
            End Select
            
            If .Lvl > 2 Then
                CharName = CharName & " (Nv. " & .Lvl - 1 & ")"
            End If
        End If
    
    End With
    
End Sub

Public Sub RemoveCharName()
    If LenB(CharName) > 0 Then
        CharName = vbNullString
    End If
End Sub

Public Sub RenderDamage()
    
    If LenB(Damage) < 1 Then
        Exit Sub
    End If
    
    If Val(Damage) < 1 And Damage <> "Fall�s" Then
        Exit Sub
    End If
    
    If GetTickCount() - startTime > 2250 Then
        Damage = vbNullString
        Exit Sub
    End If
            
    If SUBe > 0 Then
        SUBe = SUBe - 1
    End If
    
    Y = 408 + Charlist(UserCharIndex).Body.HeadOffset.Y + SUBe
    
    Select Case Len(Damage)
        Case 1
            X = 524
        Case 2
            X = 521
        Case 3
            X = 516
        Case 6
            X = 512
    End Select
    
    If DamageType = 3 Or DamageType = 5 Then
        If Right$(Damage, 1) <> "!" Then
            Damage = Damage & "!"
            X = X + 2
        End If
    End If
    
    If DamageType > 3 And SUBe = 19 Then
        Call Audio.mSound_PlayWav(SND_APU)
    End If
       
    Select Case DamageType
        Case 2
            RenderText X, Y, Damage, RGB(0, 180, 0)
            
            If AttackedCharIndex = UserCharIndex Then
                CharMinHP = 0
            End If
            
        Case Is > 3
            RenderText X, Y, Damage, RGB(115, 0, 0)
            
        Case Else
            RenderText X, Y, Damage, RGB(190, 0, 0)
    End Select
End Sub

Public Sub InitDamage(ByVal d As String)
    Damage = d
    startTime = GetTickCount
    SUBe = 20
    
    Gld = 0
    Call Dialogos.RemoveDialog(UserCharIndex)
    
    If RightHandEqp.ObjType = otFlecha Then
        RightHandEqp.Amount = RightHandEqp.Amount - 1
        frmMain.lblRightHandEqp.Caption = RightHandEqp.Amount
    End If
End Sub

Public Sub RemoveDamage()
    Damage = vbNullString
End Sub

Public Sub InitCharDamage(ByVal X As Integer, ByVal Y As Integer)
    CharX = X
    CharY = Y
    
    If LenB(CharDamage) > 0 Then
        CharDamage2 = CharDamage
        CharDamage = vbNullString
        startTime4 = GetTickCount
        SUBe4 = 20
    End If
End Sub

Public Sub RenderCharDamage()

On Error Resume Next
    
    If AttackerCharIndex < 1 Then
        Exit Sub
    End If
    
    If GetTickCount() - startTime4 > 3000 Then
        CharDamage2 = vbNullString
        CharDamageType = 1
        Exit Sub
    End If
    
    If LenB(CharDamage2) < 1 Then
        Exit Sub
    End If
    
    If SUBe4 > 0 Then
        SUBe4 = SUBe4 - 1
        CharY = CharY + SUBe4
    End If
                
    If Charlist(AttackerCharIndex).Head.Head(Charlist(AttackerCharIndex).Heading).GrhIndex > 0 Then
        CharY = CharY - GrhData(Charlist(AttackerCharIndex).Body.Walk(1).GrhIndex).PixelHeight + Charlist(AttackerCharIndex).Body.HeadOffset.Y
    Else
        CharY = CharY - GrhData(Charlist(AttackerCharIndex).Body.Walk(1).GrhIndex).PixelHeight
    End If
        
    If AttackedCharIndex = AttackerCharIndex Then
        If CharMinHP > 0 Then
            CharY = CharY - 8
        End If
    End If
    
    CharY = CharY + 8
        
    Select Case Len(CharDamage2)
        Case 1
            CharX = CharX + 12
        Case 2
            CharX = CharX + 8
        Case 3
            CharX = CharX + 4
        Case 5
            CharX = CharX + 1
    End Select
        
    Select Case CharDamageType
        Case 2
            RenderText CharX, CharY, CharDamage2, RGB(0, 180, 0)
        Case Else
            RenderText CharX, CharY, CharDamage2, RGB(180, 0, 0)
    End Select
End Sub

Public Sub RenderCharHP()
    
    If AttackedCharIndex = 0 Then
        Exit Sub
    End If
    
    If GetTickCount() - startTime > 5000 Then
        CharMinHP = 0
        Exit Sub
    End If
    
    If CharMinHP < 1 Then
        Exit Sub
    End If
    
    If Charlist(AttackedCharIndex).Head.Head(Charlist(AttackedCharIndex).Heading).GrhIndex > 0 Then
        CharY2 = CharY2 - GrhData(Charlist(AttackedCharIndex).Body.Walk(1).GrhIndex).PixelHeight + Charlist(AttackedCharIndex).Body.HeadOffset.Y
    Else
        CharY2 = CharY2 - GrhData(Charlist(AttackedCharIndex).Body.Walk(1).GrhIndex).PixelHeight
    End If
    
    CharY2 = CharY2 + 18
'
'    BackBufferSurface.SetForeColor RGB(80, 0, 0)
'    BackBufferSurface.SetFillColor RGB(140, 0, 0)
'    BackBufferSurface.SetFillStyle 0
'    BackBufferSurface.DrawRoundedBox CharX2 + 1, CharY2, CharX2 + 31, CharY2 + 4, 0, 0
'
'    BackBufferSurface.SetForeColor RGB(0, 50, 0)
'    BackBufferSurface.SetFillColor RGB(0, 100, 0)
'
'    If 0.3 * CharMinHP < 2 Then
'        BackBufferSurface.DrawRoundedBox CharX2 + 1, CharY2, CharX2 + 3, CharY2 + 4, 0, 0
'    ElseIf 0.3 * CharMinHP > 1 Then
'        BackBufferSurface.DrawRoundedBox CharX2 + 1, CharY2, CharX2 + 1 + 30 * CharMinHP / 100, CharY2 + 4, 0, 0
'    End If
'
'    BackBufferSurface.SetForeColor vbBlack
'    BackBufferSurface.SetFillStyle 1
'    BackBufferSurface.DrawRoundedBox CharX2, CharY2 - 1, CharX2 + 32, CharY2 + 5, 4, 4
End Sub

Public Sub InitCharHP(ByVal X As Integer, ByVal Y As Integer)
    CharX2 = X
    CharY2 = Y
End Sub

Public Sub RenderExp()

    If LenB(Exp) < 1 Or Exp = "0" Then
        Exit Sub
    End If

    If (GetTickCount() - StartTime2) >= 1000 Then
        Exp = vbNullString
        Exit Sub
    End If
                
    If SUBe2 > 0 Then
        SUBe2 = SUBe2 - 1
    End If
    
    If LenB(Damage) < 1 Then
        Y2 = 408 + Charlist(UserCharIndex).Body.HeadOffset.Y + SUBe2
    Else
        Y2 = 393 + Charlist(UserCharIndex).Body.HeadOffset.Y + SUBe2
    End If
    
    X2 = 528 - 4 * Len(Exp)
    
    Select Case Len(Exp)
        Case 1
            X2 = 523
        Case 2
            X2 = 520
        Case 3
            X2 = 517
        Case 4
            X2 = 513
        Case 5
            X2 = 509
    End Select
         
    RenderText X2, Y2, Exp, RGB(0, 90, 150)
End Sub

Public Sub InitExp(ByVal E As String)
    Exp = E
    StartTime2 = GetTickCount
    SUBe2 = 30
   
    Gld = 0
    Call Dialogos.RemoveDialog(UserCharIndex)
End Sub

Public Sub RemoveExp()
   Exp = vbNullString
End Sub

Public Sub RenderGld()
    If Gld = 0 Then
        Exit Sub
    End If
    
    If GetTickCount() - StartTime3 >= 2000 Then
        Gld = 0
        Exit Sub
    End If
        
    If SUBe3 > 0 Then
        SUBe3 = SUBe3 - 1
    End If
    
    Y3 = 401 + Charlist(UserCharIndex).Body.HeadOffset.Y + SUBe3
        
    Dim Gold As String
    
    If Gld > 0 Then
        Gold = "+ " & PonerPuntos(CStr(Gld))
        X3 = 520 - 4 * Len(CStr(Gld))
    Else
        Gold = "- " & PonerPuntos(CStr(-Gld))
        X3 = 520 - 4 * Len(CStr(-Gld))
    End If
    
    If Gld > 0 Then
        RenderText X3, Y3, Gold, RGB(200, 160, 0)
    Else
        RenderText X3, Y3, Gold, RGB(140, 100, 0)
    End If
End Sub

Public Sub InitGld(ByVal g As Long)
    Gld = g
    StartTime3 = GetTickCount
    SUBe3 = 20
   
    Damage = vbNullString
    ObjName = 0

    Call Dialogos.RemoveDialog(UserCharIndex)
End Sub

Public Sub RemoveGld()
    Gld = 0
End Sub

Public Sub RenderCoord()
    Const posX = 259
    Const posY = 640
    
    RenderText posX + 1, posY, "X: " & UserPos.X & " Y: " & UserPos.Y, RGB(200, 190, 150)
    RenderText posX + 1, posY + 15, "Mapa: " & UserMap, RGB(200, 190, 150)
End Sub

Public Sub RenderFPS()
    Const posX = 775
    Const posY = 258
    
    RenderText posX, posY, str(ModTileEngine.FPS), RGB(200, 190, 150)
End Sub

Private Function GetElapsedTime() As Single
'Gets the time that past since the last call

    Dim start_time As Currency
    Static end_time As Currency
    Static timer_freq As Currency

    'Get the timer frequency
    If timer_freq = 0 Then
        QueryPerformanceFrequency timer_freq
    End If
    
    'Get current time
    Call QueryPerformanceCounter(start_time)
    
    'Calculate elapsed time
    GetElapsedTime = (start_time - end_time) / timer_freq * 1000
    
    'Get next end time
    Call QueryPerformanceCounter(end_time)
End Function

Private Sub CharRender(ByVal CharIndex As Long, ByVal PixelOffsetX As Integer, ByVal PixelOffsetY As Integer)

On Error GoTo Errorcito

    Dim Moved As Boolean
    Dim Pos As Integer
    Dim color As Long
    
    With Charlist(CharIndex)
    
        If .Heading < 1 Then
            Exit Sub
        End If
        
        If .Moving Then
            'If needed, move left and right
            If .ScrollDirectionX <> 0 Then
                .MoveOffsetX = .MoveOffsetX + ScrollPixelsPerFrameX * Sgn(.ScrollDirectionX) * timerTicksPerFrame
                
                'Start animations
'TODO : Este parche es para evita los uncornos ObjNameloten al moverse! REVER!
                If .Body.Walk(.Heading).Speed > 0 Then
                    .Body.Walk(.Heading).Started = 1
                    .Arma.WeaponWalk(.Heading).Started = 1
                    .Escudo.ShieldWalk(.Heading).Started = 1
                End If
                
                'Char moved
                Moved = True
                
                'Check if we already got there
                If (Sgn(.ScrollDirectionX) = 1 And .MoveOffsetX >= 0) Or _
                        (Sgn(.ScrollDirectionX) = -1 And .MoveOffsetX <= 0) Then
                    .MoveOffsetX = 0
                    .ScrollDirectionX = 0
                End If
            End If
            
            'If needed, move up and down
            If .ScrollDirectionY <> 0 Then
                .MoveOffsetY = .MoveOffsetY + ScrollPixelsPerFrameY * 1 * Sgn(.ScrollDirectionY) * timerTicksPerFrame
                
                'Start animations
                If .Body.Walk(.Heading).Speed > 0 Then
                    .Body.Walk(.Heading).Started = 1
                    .Arma.WeaponWalk(.Heading).Started = 1
                    .Escudo.ShieldWalk(.Heading).Started = 1
                End If
                
                'Char moved
                Moved = True
                
                'Check if we already got there
                If (Sgn(.ScrollDirectionY) = 1 And .MoveOffsetY >= 0) Or _
                        (Sgn(.ScrollDirectionY) = -1 And .MoveOffsetY <= 0) Then
                    .MoveOffsetY = 0
                    .ScrollDirectionY = 0
                End If
            End If
        End If
        
        PixelOffsetX = PixelOffsetX + .MoveOffsetX
        PixelOffsetY = PixelOffsetY + .MoveOffsetY
                
        If .Head.Head(.Heading).GrhIndex > 0 Then
            If Not .Invisible Then
                'Call SurfaceSombra(BackBufferSurface, .Body.Walk(.Heading), PixelOffsetX + .Body.HeadOffset.X + 5, PixelOffsetY + .Body.HeadOffset.Y - 15, 1, 0)
                'http://blisse-games.com.ar/sombra-en-dx7-t1556.html
                If AlphaBActivated Then

                    'Draw Body
                    If .Body.Walk(.Heading).GrhIndex > 0 Then
                        If .iHead = CASPER_HEAD Then
                            Call DDrawTransGrhtoSurfaceAlpha(.Body.Walk(.Heading), PixelOffsetX, PixelOffsetY, 1, 1)
                        ElseIf CharIndex = SelectedCharIndex Then
                            Call SurfaceColor(.Body.Walk(.Heading), PixelOffsetX, PixelOffsetY, 225, 225, 50)
                        ElseIf .Paralizado Then
                            Call SurfaceColor(.Body.Walk(.Heading), PixelOffsetX, PixelOffsetY, 200, 200, 255, True)
                        'ElseIf .Lvl = 3 Then
                        '    Call SurfaceColor(.Body.Walk(.Heading), PixelOffsetX, PixelOffsetY, 255, 230, 0)
                        'ElseIf .Lvl = 4 Then
                        '    Call SurfaceColor(.Body.Walk(.Heading), PixelOffsetX, PixelOffsetY, 255, 0, 0)
                        Else
                            Call DDrawTransGrhtoSurface(.Body.Walk(.Heading), PixelOffsetX, PixelOffsetY, 1, 1)
                        End If
                    End If
                
                    'Draw Head
                    If .Head.Head(.Heading).GrhIndex > 0 Then
                        If .iHead = CASPER_HEAD Then
                            Call DDrawTransGrhtoSurfaceAlpha(.Head.Head(.Heading), PixelOffsetX + .Body.HeadOffset.X, PixelOffsetY + .Body.HeadOffset.Y, 1, 0)
                        ElseIf CharIndex = SelectedCharIndex Then
                            Call SurfaceColor(.Head.Head(.Heading), PixelOffsetX + .Body.HeadOffset.X, PixelOffsetY + .Body.HeadOffset.Y, 225, 225, 50)
                        ElseIf .Paralizado Then
                            Call SurfaceColor(.Head.Head(.Heading), PixelOffsetX + .Body.HeadOffset.X, PixelOffsetY + .Body.HeadOffset.Y, 200, 200, 255, True)
                        'ElseIf .Lvl = 3 Then
                        '    Call SurfaceColor(.Head.Head(.Heading), PixelOffsetX, PixelOffsetY, 255, 230, 0)
                        'ElseIf .Lvl = 4 Then
                        '    Call SurfaceColor(.Head.Head(.Heading), PixelOffsetX, PixelOffsetY, 255, 0, 0)
                        Else
                            Call DDrawTransGrhtoSurface(.Head.Head(.Heading), PixelOffsetX + .Body.HeadOffset.X, PixelOffsetY + .Body.HeadOffset.Y, 1, 0)
                        End If
                    
                    
                        'Draw Helmet
                        If .Casco.Head(.Heading).GrhIndex > 0 Then
                            If .Paralizado Then
                                Call SurfaceColor(.Casco.Head(.Heading), PixelOffsetX + .Body.HeadOffset.X, PixelOffsetY + .Body.HeadOffset.Y - 34, 200, 200, 255, True)
                            Else
                                Call DDrawTransGrhtoSurface(.Casco.Head(.Heading), PixelOffsetX + .Body.HeadOffset.X, PixelOffsetY + .Body.HeadOffset.Y - 34, 1, 0)
                            End If
                        End If
                        
                        'Draw Weapon
                        If .Arma.WeaponWalk(.Heading).GrhIndex > 0 Then
                            If .Paralizado Then
                                Call SurfaceColor(.Arma.WeaponWalk(.Heading), PixelOffsetX, PixelOffsetY, 200, 200, 255, True)
                            Else
                                Call DDrawTransGrhtoSurface(.Arma.WeaponWalk(.Heading), PixelOffsetX, PixelOffsetY, 1, 1)
                            End If
                        End If
                        
                        'Draw Shield
                        If .Escudo.ShieldWalk(.Heading).GrhIndex > 0 Then
                            If .Paralizado Then
                                Call SurfaceColor(.Escudo.ShieldWalk(.Heading), PixelOffsetX, PixelOffsetY, 200, 200, 255, True)
                            Else
                                Call DDrawTransGrhtoSurface(.Escudo.ShieldWalk(.Heading), PixelOffsetX, PixelOffsetY, 1, 1)
                            End If
                        End If
                    End If
                
                Else
                    'Draw Body
                    If .Body.Walk(.Heading).GrhIndex > 0 Then
                        Call DDrawTransGrhtoSurface(.Body.Walk(.Heading), PixelOffsetX, PixelOffsetY, 1, 1)
                    End If
                
                    'Draw Head
                    Call DDrawTransGrhtoSurface(.Head.Head(.Heading), PixelOffsetX + .Body.HeadOffset.X, PixelOffsetY + .Body.HeadOffset.Y, 1, 0)
                    
                    'Draw Helmet
                    If .Casco.Head(.Heading).GrhIndex > 0 Then
                        Call DDrawTransGrhtoSurface(.Casco.Head(.Heading), PixelOffsetX + .Body.HeadOffset.X, PixelOffsetY + .Body.HeadOffset.Y - 34, 1, 0)
                    End If
                        
                    'Draw Weapon
                    If .Arma.WeaponWalk(.Heading).GrhIndex > 0 Then
                        Call DDrawTransGrhtoSurface(.Arma.WeaponWalk(.Heading), PixelOffsetX, PixelOffsetY, 1, 1)
                    End If
                        
                    'Draw Shield
                    If .Escudo.ShieldWalk(.Heading).GrhIndex > 0 Then
                        Call DDrawTransGrhtoSurface(.Escudo.ShieldWalk(.Heading), PixelOffsetX, PixelOffsetY, 1, 1)
                    End If
                End If
                    
                'Draw name over head
                If .EsUser Then
                    If Nombres Then
                        Pos = getTagPosition(.Nombre)
                        
                        If CharIndex = SelectedCharIndex Then
                            Call RenderTextCentered(PixelOffsetX + 32 * 0.5 + 5, PixelOffsetY + 30, .Nombre, RGB(255, 225, 50))
                        Else
                            If .Priv < 2 Then
                                'If .Lvl > 14 Then
                                    color = RGB(230 - .Lvl * 2.5, 230 - .Lvl * 2.5, 100)
                                'Else
                                '    Color = RGB(230, 230, 100)
                                'End If
                            Else
                                color = RGB(120, 210, 0)
                            End If
                                    
                            'Nick
                            Call RenderTextCentered(PixelOffsetX + 32 * 0.5 + 5, PixelOffsetY + 30, .Nombre, color)
                        End If
                        
                        'Guilda
                        If LenB(.Guilda) > 0 Then
                            If CharIndex = SelectedCharIndex Then
                                color = RGB(255, 225, 50)
                            Else
                                
                                Select Case .AlineacionGuilda
                                    Case 1
                                        color = RGB(120, 0, 0)
                                    Case 2
                                        color = RGB(255, 80, 80)
                                    Case 3
                                        color = RGB(167, 167, 167)
                                    Case 4
                                        color = RGB(0, 0, 150)
                                    Case 5
                                        color = RGB(0, 70, 150)
                                    Case 6
                                        color = RGB(120, 255, 120)
                                End Select
                            End If
                            
                            Call RenderTextCentered(PixelOffsetX + 32 * 0.5 + 5, PixelOffsetY + 45, "<" & .Guilda & ">", color)
                        End If
                    End If
                    
                ElseIf CharIndex = SelectedCharIndex Then
                    Call RenderTextCentered(PixelOffsetX + 32 * 0.5 + 5, PixelOffsetY + 32, .Nombre, RGB(255, 225, 50))
                
                'ElseIf Abs(MouseTileX - .Pos.x) < 1 And Abs(MouseTileY - .Pos.y) < 1 Then
                
                '    Select Case .Lvl
                '        Case 1
                '            Call RenderTextCenteRed(PixelOffsetX + 32 * 0.5 + 5, PixelOffsetY + 32, .Nombre, RGB(220, 220, 220), frmCharge.font)
                '        Case 2
                '            Call RenderTextCenteRed(PixelOffsetX + 32 * 0.5 + 5, PixelOffsetY + 32, .Nombre, RGB(200, 150, 120), frmCharge.font)
                '        Case 3
                '            Call RenderTextCenteRed(PixelOffsetX + 32 * 0.5 + 5, PixelOffsetY + 32, .Nombre & " (Nv. 2)", RGB(200, 150, 85), frmCharge.font)
                '        Case 4
                '            Call RenderTextCenteRed(PixelOffsetX + 32 * 0.5 + 5, PixelOffsetY + 32, .Nombre & " (Nv. 3)", RGB(200, 150, 30), frmCharge.font)
                '    End Select
                End If
                
            'ALPHA SI ESTA INVISIBLE
            ElseIf CharIndex = UserCharIndex Or _
                LenB(.Guilda) > 0 And .Guilda = Charlist(UserCharIndex).Guilda Or _
                (Charlist(UserCharIndex).Priv > 1) Then
                                                              
                'CON ALPHABACTIVATED
                If AlphaBActivated Then
                
                    'Draw Body
                    If .Body.Walk(.Heading).GrhIndex > 0 Then
                        Call DDrawTransGrhtoSurfaceAlpha(.Body.Walk(.Heading), PixelOffsetX, PixelOffsetY, 1, 1)
                    End If
                
                    'Draw Head
                    If .Head.Head(.Heading).GrhIndex > 0 Then
                        Call DDrawTransGrhtoSurfaceAlpha(.Head.Head(.Heading), PixelOffsetX + .Body.HeadOffset.X, PixelOffsetY + .Body.HeadOffset.Y, 1, 0)
                    
                        'Draw Helmet
                        If .Casco.Head(.Heading).GrhIndex > 0 Then
                            Call DDrawTransGrhtoSurfaceAlpha(.Casco.Head(.Heading), PixelOffsetX + .Body.HeadOffset.X, PixelOffsetY + .Body.HeadOffset.Y - 34, 1, 0)
                        End If
                            
                        'Draw Weapon
                        If .Arma.WeaponWalk(.Heading).GrhIndex > 0 Then
                            Call DDrawTransGrhtoSurfaceAlpha(.Arma.WeaponWalk(.Heading), PixelOffsetX, PixelOffsetY, 1, 1)
                        End If
                        
                        'Draw Shield
                        If .Escudo.ShieldWalk(.Heading).GrhIndex > 0 Then
                            Call DDrawTransGrhtoSurfaceAlpha(.Escudo.ShieldWalk(.Heading), PixelOffsetX, PixelOffsetY, 1, 1)
                        End If
                    Else
                        Call DDrawTransGrhtoSurface(.Head.Head(.Heading), PixelOffsetX + .Body.HeadOffset.X, PixelOffsetY + .Body.HeadOffset.Y, 1, 0)
                    End If
                    
                'SIN ALPHABACTIVATED
                Else
                    'Draw Body
                    If .Body.Walk(.Heading).GrhIndex > 0 Then
                        Call DDrawTransGrhtoSurface(.Body.Walk(.Heading), PixelOffsetX, PixelOffsetY, 1, 1)
                    End If
                
                    'Draw Head
                    Call DDrawTransGrhtoSurface(.Head.Head(.Heading), PixelOffsetX + .Body.HeadOffset.X, PixelOffsetY + .Body.HeadOffset.Y, 1, 0)
                    
                    'Draw Helmet
                    If .Casco.Head(.Heading).GrhIndex > 0 Then
                        Call DDrawTransGrhtoSurface(.Casco.Head(.Heading), PixelOffsetX + .Body.HeadOffset.X, PixelOffsetY + .Body.HeadOffset.Y - 34, 1, 0)
                    End If
                        
                    'Draw Weapon
                    If .Arma.WeaponWalk(.Heading).GrhIndex > 0 Then
                        Call DDrawTransGrhtoSurface(.Arma.WeaponWalk(.Heading), PixelOffsetX, PixelOffsetY, 1, 1)
                    End If
                        
                    'Draw Shield
                    If .Escudo.ShieldWalk(.Heading).GrhIndex > 0 Then
                        Call DDrawTransGrhtoSurface(.Escudo.ShieldWalk(.Heading), PixelOffsetX, PixelOffsetY, 1, 1)
                    End If
                End If

                'Draw name over head
                If Nombres Then
                    Pos = getTagPosition(.Nombre)
                
                    If .Priv < 2 Then
                        'If .Lvl > 14 Then
                            color = RGB(230 - .Lvl * 2.5, 230 - .Lvl * 2.5, 100)
                        'Else
                        '    Color = RGB(230, 230, 100)
                        'End If
                    Else
                        color = RGB(120, 210, 0)
                    End If
                            
                    'Nick
                    Call RenderTextCentered(PixelOffsetX + 32 * 0.5 + 5, PixelOffsetY + 30, .Nombre, color)

                    'Guilda
                    If LenB(.Guilda) > 0 Then
                        Call RenderTextCentered(PixelOffsetX + 32 * 0.5 + 5, PixelOffsetY + 45, "<" & .Guilda & ">", &HC0FFFF)
                    End If
                End If
            End If

        'Draw Body
        ElseIf .Body.Walk(.Heading).GrhIndex > 0 Then
  
            If AlphaBActivated Then
                If CharIndex = SelectedCharIndex Then
                    Call SurfaceColor(.Body.Walk(.Heading), PixelOffsetX, PixelOffsetY, 225, 225, 50)
                ElseIf .Paralizado Then
                    Call SurfaceColor(.Body.Walk(.Heading), PixelOffsetX, PixelOffsetY, 200, 200, 255, True)
                'ElseIf .Lvl = 3 Then
                '    Call SurfaceColor(.Body.Walk(.Heading), PixelOffsetX, PixelOffsetY, 230, 150, 0)
                'ElseIf .Lvl = 4 Then
                '    Call SurfaceColor(.Body.Walk(.Heading), PixelOffsetX, PixelOffsetY, 255, 70, 0)
                Else
                    Call DDrawTransGrhtoSurface(.Body.Walk(.Heading), PixelOffsetX, PixelOffsetY, 1, 1)
                End If
            Else
                Call DDrawTransGrhtoSurface(.Body.Walk(.Heading), PixelOffsetX, PixelOffsetY, 1, 1)
            End If
            
            'Draw name over head
            If Nombres Then
                If .EsUser Then
                    Pos = getTagPosition(.Nombre)
                                  
                    If .Priv < 2 Then
                        'If .Lvl > 14 Then
                            color = RGB(230 - .Lvl * 2.5, 230 - .Lvl * 2.5, 100)
                        'Else
                        '    Color = RGB(230, 230, 100)
                        'End If
                    Else
                        color = RGB(120, 210, 0)
                    End If
                         
                    Call RenderTextCentered(PixelOffsetX + 32 * 0.5 + 5, PixelOffsetY + 30, .Nombre, color)
                        
                    'Guilda
                    If LenB(.Guilda) > 0 Then
                        Select Case .AlineacionGuilda
                            Case 1
                                color = RGB(120, 0, 0)
                            Case 2
                                color = RGB(255, 80, 80)
                            Case 3
                                color = RGB(167, 167, 167)
                            Case 4
                                color = RGB(0, 0, 150)
                            Case 5
                                color = RGB(0, 70, 150)
                            Case 6
                                color = RGB(120, 255, 120)
                        End Select
                        
                        Call RenderTextCentered(PixelOffsetX + 32 * 0.5 + 5, PixelOffsetY + 45, "<" & .Guilda & ">", color)
                    End If
                    
                'NOMBRE DE NPC
                ElseIf CharIndex = SelectedCharIndex Then
                    Call RenderTextCentered(PixelOffsetX + 32 * 0.5 + 5, PixelOffsetY + 32, .Nombre, RGB(255, 225, 50))
                
                'ElseIf Abs(MouseTileX - .Pos.x) < 1 And Abs(MouseTileY - .Pos.y) < 1 Then
                '    Select Case .Lvl
                '        Case 1
                '            Call RenderTextCenteRed(PixelOffsetX + 32 * 0.5 + 5, PixelOffsetY + 32, .Nombre, RGB(220, 220, 220), frmCharge.font)
                '        Case 2
                '            Call RenderTextCenteRed(PixelOffsetX + 32 * 0.5 + 5, PixelOffsetY + 32, .Nombre, RGB(200, 150, 120), frmCharge.font)
                '        Case 3
                '            Call RenderTextCenteRed(PixelOffsetX + 32 * 0.5 + 5, PixelOffsetY + 32, .Nombre & " (Nv. 2)", RGB(200, 150, 85), frmCharge.font)
                '        Case 4
                '            Call RenderTextCenteRed(PixelOffsetX + 32 * 0.5 + 5, PixelOffsetY + 32, .Nombre & " (Nv. 3)", RGB(200, 150, 30), frmCharge.font)
                '    End Select
                End If
            End If
        End If
        
        'Update dialogs
        Call Dialogos.UpdateDialogPos(PixelOffsetX + .Body.HeadOffset.X, PixelOffsetY + .Body.HeadOffset.Y - 34, CharIndex)
        
        'Draw FX
        If .FxIndex > 0 Then
            If AlphaBActivated Then
                Call DDrawTransGrhtoSurfaceAlpha(.fX, PixelOffsetX + FxData(.FxIndex).OffsetX, PixelOffsetY + FxData(.FxIndex).OffsetY, 1, 1)
            Else
                Call DDrawTransGrhtoSurface(.fX, PixelOffsetX + FxData(.FxIndex).OffsetX, PixelOffsetY + FxData(.FxIndex).OffsetY, 1, 1)
            End If
            
            'Check if animation is over
            If .fX.Started < 1 Then
                .FxIndex = 0
            End If
        End If
                        
        If CharIndex = AttackedCharIndex Then
            If CharIndex <> UserCharIndex Then
                Call InitCharHP(PixelOffsetX, PixelOffsetY)
            End If
        End If
        
        If CharIndex = AttackerCharIndex Then
            Call InitCharDamage(PixelOffsetX, PixelOffsetY)
        End If
        
    End With
 
Errorcito:
End Sub


Public Sub SurfaceColor(Grh As Grh, ByVal X As Integer, ByVal Y As Integer, ByVal r As Byte, ByVal g As Byte, ByVal B As Byte, Optional ByVal Paralized As Boolean = False)

    Dim iGrhIndex As Integer
    Dim SourceRect As RECT
     
    If Grh.GrhIndex = 0 Then
        Exit Sub
    End If
     
    If Not Paralized And Grh.Started = 1 Then
        Grh.FrameCounter = Grh.FrameCounter + (timerElapsedTime * GrhData(Grh.GrhIndex).NumFrames / Grh.Speed)
                
        If Grh.FrameCounter > GrhData(Grh.GrhIndex).NumFrames Then
            Grh.FrameCounter = (Grh.FrameCounter Mod GrhData(Grh.GrhIndex).NumFrames) + 1
                    
            If Grh.Loops <> INFINITE_LOOPS Then
                If Grh.Loops > 0 Then
                    Grh.Loops = Grh.Loops - 1
                Else
                    Grh.Started = 0
                End If
            End If
        End If
    End If
    
    iGrhIndex = GrhData(Grh.GrhIndex).Frames(Grh.FrameCounter)
     
    If GrhData(iGrhIndex).TileWidth <> 1 Then
        X = X - Int(GrhData(iGrhIndex).TileWidth * 16) + 16 'hard coded for speed
    End If
    
    If GrhData(iGrhIndex).TileHeight <> 1 Then
        Y = Y - Int(GrhData(iGrhIndex).TileHeight * 32) + 32 'hard coded for speed
    End If
     
    With SourceRect
        .Left = GrhData(iGrhIndex).sX + IIf(X < 0, Abs(X), 0)
        .Top = GrhData(iGrhIndex).sY + IIf(Y < 0, Abs(Y), 0)
        .Right = .Left + GrhData(iGrhIndex).PixelWidth
        .bottom = .Top + GrhData(iGrhIndex).PixelHeight
    End With
'
'    Set Src = SurfaceDB.Surface(GrhData(iGrhIndex).FileNum)
'
'    Src.GetSurfaceDesc ddsdSrc
'    BackBufferSurface.GetSurfaceDesc ddsdDest
'
'    With rDest
'        .Left = X
'        .Top = Y
'        .Right = X + GrhData(iGrhIndex).PixelWidth
'        .bottom = Y + GrhData(iGrhIndex).PixelHeight
'
'        If .Right > ddsdDest.lWidth Then
'            .Right = ddsdDest.lWidth
'        End If
'        If .bottom > ddsdDest.lHeight Then
'            .bottom = ddsdDest.lHeight
'        End If
'    End With
'
'    Dim SrcLock As Boolean, DstLock As Boolean
'
'On Error GoTo HayErrorAlpha
'
'    If X < 0 Then
'        Exit Sub
'    End If
'
'    If Y < 0 Then
'        Exit Sub
'    End If
'
'    Src.Lock SourceRect, ddsdSrc, DDLOCK_NOSYSLOCK Or DDLOCK_WAIT, 0
'    BackBufferSurface.Lock rDest, ddsdDest, DDLOCK_NOSYSLOCK Or DDLOCK_WAIT, 0
'
'    BackBufferSurface.GetLockedArray dArray()
'    Src.GetLockedArray sArray()
'
'    Call vbDABLcolorblend16565ck(ByVal VarPtr(sArray(SourceRect.Left + SourceRect.Left, SourceRect.Top)), ByVal VarPtr(dArray(X + X, Y)), 65, rDest.Right - rDest.Left, rDest.bottom - rDest.Top, ddsdSrc.lPitch, ddsdDest.lPitch, r, g, B)
'    BackBufferSurface.Unlock rDest
'    Src.Unlock SourceRect
'
'    Exit Sub
'
'HayErrorAlpha:
'        'Grh.Started = 0
'        'Grh.FrameCounter = 0
'        'Grh.Loops = 0
'        'Grh.Speed = 0
'        'Grh.GrhIndex = 0
'
'        BackBufferSurface.Unlock rDest
'        Src.Unlock SourceRect
End Sub

Public Sub GenerarMiniMapa()

     
End Sub

Public Sub DibujarMiniMapa()


End Sub


