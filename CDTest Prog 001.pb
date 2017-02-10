IncludeFile "CDPrint.pbi"

Enumeration WinMain
  #WinMain
  #btnPrint
EndEnumeration
  
  Define Event.i
  Define Orientation.i
  
  OpenWindow(#WinMain, 5, 5, 600, 400, "CDPrint Test Programme", #PB_Window_SystemMenu)
  ButtonGadget(#btnPrint, 130, 230, 110, 20, "Print")
 
  Repeat
   
    Event = WaitWindowEvent()
   
    Select Event
       
      Case #PB_Event_Gadget
        
        Select EventGadget()
            
          Case #btnPrint
            
            If CDPrint::Open("Test Print",CDPrint::#Preview)
              
              If CDPrint::Printer\Height > CDPrint::Printer\Width
                Orientation = CDPrint::#Portrait
              Else
                Orientation = CDPrint::#Landscape
              EndIf
              
              CDPrint::AddPage(Orientation)
              CDPrint::PrintLine(20,20,CDPrint::Printer\Width - 20,20,1)
              CDPrint::PrintLine(CDPrint::Printer\Width/2,10,CDPrint::Printer\Width/2,CDPrint::Printer\Height - 20,1)            
              CDPrint::Finished()
            EndIf
           
        EndSelect
       
    EndSelect
   
  Until Event = #PB_Event_CloseWindow
; IDE Options = PureBasic 5.60 Beta 3 (Windows - x64)
; CursorPosition = 36
; FirstLine = 15
; EnableXP