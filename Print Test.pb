EnableExplicit

IncludeFile "CDPrint.pbi"

Enumeration WinMain
  #WinMain
  #btnPrint
EndEnumeration

Define Event.i


Procedure PrintMyPages()
  
  CDPrint::Open("Test Print",CDPrint::#Preview) ;Can Be CDPrint::#NoPreview as well
  CDPrint::AddPage(CDPrint::#Portrait)
  CDPrint::PrintLine(12,32,45,87,1)
  CDPrint::PrintBox(20,20,50,50,5)
  CDPrint::AddPage(CDPrint::#Portrait)
  CDPrint::PrintText(20,20,"Arial",32,"The Quick Brown Fox")
  CDPrint::AddPage(CDPrint::#Landscape) 
  CDPrint::PrintImage(GetCurrentDirectory() + "Eiffel.jpg",5,5,100,50)
  CDPrint::Finished()

EndProcedure

OpenWindow(#WinMain, 5, 5, 600, 400, "CDPrint Test Programme", #PB_Window_SystemMenu)
ButtonGadget(#btnPrint, 130, 210, 110, 20, "Print")

Repeat
    
  Event = WaitWindowEvent()
  
  Select Event
      
    Case #PB_Event_CloseWindow
      
      End

    Case #PB_Event_Gadget
      
      Select EventGadget()
          
        Case #btnPrint
          
          PrintMyPages()
          
      EndSelect
      
  EndSelect
  
ForEver
; IDE Options = PureBasic 5.60 Beta 1 (Windows - x64)
; CursorPosition = 14
; Folding = -
; EnableXP