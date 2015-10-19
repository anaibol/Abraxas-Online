Attribute VB_Name = "Mail"
Public Sub Send_Email(Para As String, De As String, Asunto As String, Mensaje As String, Optional Path_Adjunto As String)
                             
On Error GoTo Error

    'Variable de objeto Cdo.Message
    Dim Obj_Email As CDO.message
      
    'Crea un Nuevo objeto CDO.Message
    Set Obj_Email = New CDO.message
      
    'Indica el servidor Smtp para poder enviar el Mail ( puede ser el nombre del servidor o su direcci�n IP )
    Obj_Email.Configuration.Fields(cdoSMTPServer) = "mail.anaibol.com.ar"
      
    Obj_Email.Configuration.Fields(cdoSendUsingMethod) = 2
      
    'Puerto. Por defecto se usa el puerto 25, en el caso de Gmail se usan los puertos 465 o  el puerto 587 ( este �ltimo me dio error )
      
    Obj_Email.Configuration.Fields.Item("http://schemas.microsoft.com/cdo/configuration/smtpserverport") = 26
  
    'Indica el tipo de autentificaci�n con el servidor de correo _
    El valor 0 no requiere autentificarse, el valor 1 es con autentificaci�n
    Obj_Email.Configuration.Fields.Item("http://schemas.microsoft.com/cdo/configuration/smtpauthenticate") = True
      
    'Tiempo m�ximo de espera en segundos para la conexi�n
    Obj_Email.Configuration.Fields.Item("http://schemas.microsoft.com/cdo/configuration/smtpconnectiontimeout") = 10
    
    'Id de usuario del servidor Smtp ( en el caso de gmail, debe ser la direcci�n de correro mas el @gmail.com )
    Obj_Email.Configuration.Fields.Item("http://schemas.microsoft.com/cdo/configuration/sendusername") = "anaibol"
  
    'Password de la cuenta
    Obj_Email.Configuration.Fields.Item("http://schemas.microsoft.com/cdo/configuration/sendpassword") = "abrelatas0122"
  
    'Indica si se usa SSL para el env�o. En el caso de Gmail requiere que est� en True
    Obj_Email.Configuration.Fields.Item("http://schemas.microsoft.com/cdo/configuration/smtpusessl") = False
      
      
    'Estructura del mail
    
    'Direcci�n del Destinatario
    Obj_Email.To = Para
      
    'Direcci�n del remitente
    Obj_Email.from = De
      
    'Asunto del mensaje
    Obj_Email.Subject = Asunto
      
    'Cuerpo del mensaje
    Obj_Email.TextBody = Mensaje
      
    'Ruta del archivo adjunto
    If Path_Adjunto <> vbNullString Then
        Obj_Email.AddAttachment (Path_Adjunto)
    End If
      
    'Actualiza los datos antes de enviar
    Obj_Email.Configuration.Fields.Update
      
    On Error Resume Next
    'Env�a el Email
    Obj_Email.send
      
    'Descarga la referencia
    If Not Obj_Email Is Nothing Then
        Set Obj_Email = Nothing
    End If

Error:
End Sub




