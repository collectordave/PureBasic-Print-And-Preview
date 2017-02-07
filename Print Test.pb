EnableExplicit

IncludeFile "CDprint.pbi"

Enumeration WinMain
  #WinMain
  #btnPrint
  #Canvas
EndEnumeration

Procedure PrintMyPages()
  
  Define iLoop.i
  
  If CDPrint::Open("Test Print",CDPrint::#Preview) ;Can Be CDPrint::#NoPreview as well
    CDPrint::AddPage(CDPrint::#Portrait)
    For iLoop = 20 To 280 Step 20
    CDPrint::PrintLine(10,iLoop,CDPrint::Printer\width - 10,iLoop,0.1, RGBA(100, 100, 100, 128))
    Next iLoop
    CDPrint::PrintBox(20,20,50,50,5, RGBA(10, 200, 20, 128))
    CDPrint::AddPage(CDPrint::#Portrait)
    CDPrint::PrintText(20,20,"Arial",32,"The Quick Brown Fox")
    CDPrint::AddPage(CDPrint::#Landscape)
    CDPrint::PrintImageFromFile(GetCurrentDirectory() + "Eiffel.jpg",5,5,100,50, 128)
    CDPrint::AddPage(CDPrint::#Portrait)
    CDPrint::PrintCanvas(#Canvas,10,10,100,100)
    CDPrint::Finished()
  EndIf

EndProcedure


Define Event.i
Define x.i, y.i

UseJPEGImageDecoder()

OpenWindow(#WinMain, 5, 5, 600, 400, "CDPrint Test Programme", #PB_Window_SystemMenu)
ButtonGadget(#btnPrint, 130, 230, 110, 20, "Print")

CanvasGadget(#Canvas, 10, 10, 200, 200)
If StartDrawing(CanvasOutput(#Canvas))
  StopDrawing()
EndIf

Repeat
   
  Event = WaitWindowEvent()
 
  Select Event
     
    Case #PB_Event_CloseWindow
      End

    Case #PB_Event_Gadget
     
      Select EventGadget()
        Case #btnPrint
          PrintMyPages()
         
        Case #Canvas
          If EventType() = #PB_EventType_LeftButtonDown Or (EventType() = #PB_EventType_MouseMove And GetGadgetAttribute(#Canvas, #PB_Canvas_Buttons) & #PB_Canvas_LeftButton)
            If StartDrawing(CanvasOutput(#Canvas))
              x = GetGadgetAttribute(#Canvas, #PB_Canvas_MouseX)
              y = GetGadgetAttribute(#Canvas, #PB_Canvas_MouseY)
              Circle(x, y, 10, RGB(Random(255), Random(255), Random(255)))
              StopDrawing()
            EndIf
          EndIf

      EndSelect
     
  EndSelect
 
ForEver
; IDE Options = PureBasic 5.60 Beta 1 (Windows - x64)
; CursorPosition = 25
; FirstLine = 13
; Folding = -
; EnableXP