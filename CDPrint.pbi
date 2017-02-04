;
; ------------------------------------------------------------
;
;   PureBasic - Print/Preview Module
;
;   FileName CDPrint.pbi
;
;   
; ------------------------------------------------------------
;
EnableExplicit

UseSQLiteDatabase()
UsePNGImageDecoder()
UseJPEGImageDecoder()

DeclareModule CDPrint
  EnableExplicit
  Enumeration
    #NoPreview
    #Preview
    #Portrait
    #Landscape
  EndEnumeration    
  
  Structure Information
    Height.i                ;mm
    Width.i                 ;mm
    TopPrinterMargin.i      ;mm
    LeftPrinterMargin.i     ;mm
    BottomPrinterMargin.i   ;mm
    RightPrinterMargin.i    ;mm
    HorizontalResolution.d  ;dpmm
    VerticalResolution.d    ;dpmm
  EndStructure
  
  Global Printer.Information
  
  Declare CDPrintEvents(Event)
  Declare Open(JobName.s,Mode.i = #Preview)
  Declare ShowPage(PageID)
  Declare AddPage(Orientation.i)
  Declare Finished()
  Declare PrintLine(Startx,Starty,Endx,Endy,LineWidth)
  Declare PrintBox(X1.i,Y1.i,X2.i,Y2.i,Width.i)
  Declare PrintText(Startx,Starty,Font.s,Size.i,Text.s)
  Declare PrintImage(Image.s,Topx.i,Topy.i,Width.i,Height.i)
  Declare.f GettextWidthmm(text.s,FName.s,FSize.f)
  Declare.f GettextHeightmm(text.s,FName.s,FSize.f)
  
EndDeclareModule

Module CDPrint
  
  Enumeration 600
    #WinPageRange
    #cntRange
    #optAll
    #optRange
    #optSelected
    #strRange
    #strSelected
    #btnOk
    #btnCancel
 EndEnumeration
  
  
  Global PrintDB.i
  Global PrintJob.s
  Global PrintMode.i
  Global CurrentPage.i
  Global PageNo.i
  Global TotalPages.i
  Global PreviewImage.i
  Global ClearImage.i
  Global PageOrientation.i
  Global PrinterOrientation.i
  Global PreviewWindow.l
  Global Dim PageRange.i(0)
  Global GraphicScale.f
  Global TextScale.f  

  Macro FileExists(filename)
    Bool(FileSize(fileName) > -1)
  EndMacro 
  
  Procedure OpenPrintDB()
    
    
    PrintDB = OpenDatabase(#PB_Any, ":memory:", "", "");, #PB_Database_SQLite)
    Debug "Open DB " + Str(PrintDB)
    DatabaseUpdate(PrintDB,"CREATE TABLE [Content] ([PageNumber] INTEGER NOT NULL,[Type] VARCHAR(10)  NULL,[x1] INTEGER  NULL,[y1] INTEGER  NULL,[x2] INTEGER  NULL,[y2] INTEGER  NULL,[Width] INTEGER  NULL,[Font] VARCHAR(20)  NULL,[FontSize] INTEGER  NULL,[TextOrImage] TEXT  NULL,[Colour] INTEGER  NULL,[Flags] INTEGER  NULL);")
    DatabaseUpdate(PrintDB,"CREATE TABLE [Pages] ([PageNumber] INTEGER  NULL,[Orientation] INTEGER  NULL);")
    Debug "Error " + DatabaseError()
    
    
 ;   If FileExists(GetCurrentDirectory() + PrintJob + "\CDTemp.PRN")
 ;     PrintDB = OpenDatabase(#PB_Any,GetCurrentDirectory() + PrintJob + "\CDTemp.PRN","","")
 ;   Else
 ;    If CreateFile(0, GetCurrentDirectory() + PrintJob + "\CDTemp.PRN")
 ;      CloseFile(0)
 ;      PrintDB = OpenDatabase(#PB_Any,GetCurrentDirectory() + PrintJob + "\CDTemp.PRN","","")
 ;      DatabaseUpdate(PrintDB,"CREATE TABLE [Content] ([PageNumber] INTEGER NOT NULL,[Type] VARCHAR(10)  NULL,[x1] INTEGER  NULL,[y1] INTEGER  NULL,[x2] INTEGER  NULL,[y2] INTEGER  NULL,[Width] INTEGER  NULL,[Font] VARCHAR(20)  NULL,[FontSize] INTEGER  NULL,[TextOrImage] TEXT  NULL,[Colour] INTEGER  NULL,[Flags] INTEGER  NULL);")
 ;      DatabaseUpdate(PrintDB,"CREATE TABLE [Pages] ([PageNumber] INTEGER  NULL,[Orientation] INTEGER  NULL);")
 ;    EndIf
 ;  EndIf
   
  EndProcedure
  
  Procedure PrintPage(PageID)
    
    Define x1.i,y1.i,x2.i,y2.i,Width.i,FontSize.i,PrintImage.i
    Define Criteria.s,TextImage.s,Font.s  
    Define TextSize.f
    
    If PageID = 0
      ProcedureReturn
    EndIf

    ;Open Print Job
    ;OpenPrintDB()
    
    ;Get Page Detail
    Criteria = "SELECT * FROM Pages WHERE PageNumber = " + Str(PageID) + ";"
    DatabaseQuery(PrintDB,Criteria)    
    FirstDatabaseRow(PrintDB)
    
    ;Process Page Setup Commands
    PageOrientation = GetDatabaseLong(PrintDB,DatabaseColumnIndex(PrintDB,"Orientation"))
    FinishDatabaseQuery(PrintDB)
    
    ;Get Page Content
    Criteria = "SELECT * FROM Content WHERE PageNumber = " + Str(PageID) + ";"
    DatabaseQuery(PrintDB,Criteria)

    StartVectorDrawing(PrinterVectorOutput(#PB_Unit_Millimeter))

    ;If Printer and Page orientation different rotate
    If PageOrientation <> PrinterOrientation
      RotateCoordinates(0 , 0 , -90 )
      TranslateCoordinates( -Printer\Height , 0 ) 
    EndIf
    
    While NextDatabaseRow(PrintDB)

      ;Get all content variables
      x1 =  GetDatabaseLong(PrintDB,DatabaseColumnIndex(PrintDB,"x1"))
      y1 =  GetDatabaseLong(PrintDB,DatabaseColumnIndex(PrintDB,"y1"))          
      x2 =  GetDatabaseLong(PrintDB,DatabaseColumnIndex(PrintDB,"x2"))
      y2 =  GetDatabaseLong(PrintDB,DatabaseColumnIndex(PrintDB,"y2"))
      Width =  GetDatabaseLong(PrintDB,DatabaseColumnIndex(PrintDB,"Width"))        
      TextImage = GetDatabaseString(PrintDB,DatabaseColumnIndex(PrintDB,"TextOrImage"))
      Font = GetDatabaseString(PrintDB,DatabaseColumnIndex(PrintDB,"Font")) 
      FontSize = GetDatabaseLong(PrintDB,DatabaseColumnIndex(PrintDB,"FontSize"))
         
      ;Process Draw Page Content Commands
      Select GetDatabaseString(PrintDB,DatabaseColumnIndex(PrintDB,"Type"))
          
        Case "Line"
          
         MovePathCursor(x1, y1)
        
         AddPathLine(x2, y2, #PB_Path_Default)
        
         VectorSourceColor(RGBA(0, 0, 0, 255))
        
         StrokePath(Width, #PB_Path_RoundCorner)       
    
       Case "Box"

         AddPathBox(x1, y1, (x2 - x1), (y2 - y1))

         VectorSourceColor(RGBA(255, 0, 0, 255))
    
         StrokePath(Width)
         
       Case "Image"

         PrintImage = LoadImage(#PB_Any,GetCurrentDirectory() + "Print Temp\" + PrintJob + "\" + TextImage) 
         MovePathCursor(x1, y1)
 
         DrawVectorImage(ImageID(PrintImage),100,x2,y2)
       
       Case "Text"

         LoadFont(0, Font , FontSize )
         TextSize = FontSize * 0.352777778 ;Convert Font Points To mm
         VectorFont(FontID(0), TextSize)
         VectorSourceColor(RGBA(0, 0, 0, 255))

         MovePathCursor(x1, y1)
         DrawVectorText(TextImage)       
         FreeFont(0) 
         
     EndSelect ;Element Type  
        
    Wend
    FinishDatabaseQuery(PrintDB)
    StopVectorDrawing()
    ;CloseDatabase(PrintDB)
        
  EndProcedure 
   
  Procedure.i SetPagesToPrint()
    
    Define StartPage.i,EndPage.i,iLoop.i,PageCount.i,Retval.i,Quit.i,Event.i 

    OpenWindow(#WinPageRange, 0, 0, 250, 150, "What To Print", #PB_Window_TitleBar | #PB_Window_Tool|#PB_Window_WindowCentered)
    ContainerGadget(#cntRange, 10, 10, 230, 100)
    OptionGadget(#optAll, 10, 10, 70, 20, "All")
    OptionGadget(#optRange, 10, 40, 70, 20, "Range")
    OptionGadget(#optSelected, 10, 70, 70, 20, "Selected")
    StringGadget(#strRange, 100, 40, 130, 20, "")
    GadgetToolTip(#strRange, "Enter a single range of pages to print. For example 5-12")  
    StringGadget(#strSelected, 100, 70, 130, 20, "")
    GadgetToolTip(#strSelected, "Enter page numbers separated by commas. Example 2,6,9")  
    CloseGadgetList()
    ButtonGadget(#btnOk, 90, 120, 70, 25, "Ok")
    ButtonGadget(#btnCancel, 170, 120, 70, 25, "Cancel")
  
    ;Select all as default
    SetGadgetState(#optAll,#True)
    Quit = #False
  
    Repeat
      
      Event = WaitWindowEvent()
      Select Event
        Case #PB_Event_CloseWindow
          End
  
        Case #PB_Event_Gadget
        
          Select EventGadget()
            
            Case #btnOk
            
              If GetGadgetState(#optAll)

                ReDim PageRange(TotalPages)
                For iLoop = 0 To TotalPages -1
                  PageRange(iLoop) = iLoop + 1
                Next

              ElseIf GetGadgetState(#optSelected)
           
                PageCount = CountString(GetGadgetText(#strSelected),",") + 1
                ReDim PageRange(PageCount)
                For iLoop = 1 To PageCount
                  If Val(StringField(GetGadgetText(#strSelected),iLoop,",")) <= TotalPages
                    PageRange(iLoop - 1) = Val(StringField(GetGadgetText(#strSelected),iLoop,","))
                  Else
                    PageRange(iLoop - 1) = 0
                  EndIf
                Next
          
              ElseIf GetGadgetState(#optRange)
          
                PageCount = 0
                StartPage = Val(StringField(GetGadgetText(#strRange),1,"-"))
                EndPage = Val(StringField(GetGadgetText(#strRange),2,"-"))
                If EndPage > TotalPages  
                  EndPage = TotalPages
                EndIf
                ReDim PageRange(Endpage-Startpage + 1)
                For iLoop = 0 To ArraySize(PageRange())
                  Pagerange(iLoop) = StartPage + PageCount
                  PageCount = PageCount + 1
                Next iLoop
          
              EndIf
        
              CloseWindow(#WinPageRange)
              Quit = #True
              Retval =  #True
            
            Case #btnCancel
              CloseWindow(#WinPageRange)
              Quit = #True
              Retval =  #False
          EndSelect
      EndSelect
    
    Until  Quit = #True 
    
    ProcedureReturn RetVal   
 
  EndProcedure
  
  Procedure ShowPreview()
    
    Define Event.i,QuitPreview.i,TPageHeight.i,TPageWidth.i,iLoop.i
    
    
    #btnPrint = 64
    #btnClose = 65
    #spnPageSelect = 66
    #imgPreview = 67
   
    QuitPreview = #False
   
    ;Scale Factors For Image
    TPageHeight = Printer\Height * 2.834645669 ;mm To Points
    TPageWidth = Printer\Width * 2.834645669

    If Printer\Height > Printer\Width.i
      GraphicScale.f = 500/Printer\Height
      TextScale.f = 500/TPageHeight.i
    Else
      GraphicScale.f = 500/Printer\Width
      TextScale.f = 500/TPagewidth.i
    EndIf
  
    ;Create the image for the page
    PreviewImage = CreateImage(#PB_Any, Printer\Width * GraphicScale.f,Printer\Height * GraphicScale.f, 32,RGB(255,255,255))
    ClearImage = CreateImage(#PB_Any, Printer\Width * GraphicScale.f,Printer\Height * GraphicScale.f, 32,RGB(255,255,255))
 
    ;Open The Preview Window
    PreviewWindow = OpenWindow(#PB_Any, #PB_Ignore,#PB_Ignore, 540, 535, "Print Preview - " + PrintJob)
    SpinGadget     (#spnPageSelect, 490, 0, 50, 25, 0, 1000,#PB_Spin_Numeric)
    SetGadgetState (#spnPageSelect, 1)
    ImageGadget(#imgPreview, 5, 5, 50, 50,  0,#PB_Image_Raised)
    ButtonGadget(#btnPrint, 0, 0, 70, 20, "Print")
    ButtonGadget(#btnClose, 80, 0, 70, 20, "Close")    
    
    ;Set Page Counter To Zero And Create first Page Image
    CurrentPage = 1    
    ShowPage(CurrentPage)
        
    Repeat
    
      Event = WaitWindowEvent()
      Select Event
        Case #PB_Event_CloseWindow
          CloseWindow(PreviewWindow)
          QuitPreview = #True

        Case #PB_Event_Gadget
      
          Select EventGadget()
          
            Case #spnPageSelect
           
              If EventType() = #PB_EventType_Change
                If GetGadgetState(#spnPageSelect) > PageNo
                  CurrentPage = PageNo
                ElseIf GetGadgetState(#spnPageSelect) < 1
                  CurrentPage = 1
                Else
                  CurrentPage = GetGadgetState(#spnPageSelect)
                EndIf 
                SetGadgetState(#spnPageSelect,CurrentPage)
                ShowPage(CurrentPage)            
               EndIf
           
            Case #btnPrint
           
              If SetPagesToPrint()
                StartPrinting("Tester") 
                For iLoop = 0 To ArraySize(PageRange()) - 1
                  PrintPage(PageRange(iLoop))
                  NewPrinterPage()
                Next iLoop
                StopPrinting()
              EndIf
              CloseWindow(PreviewWindow)
              QuitPreview = #True
              
            Case #btnClose
           
              CloseWindow(PreviewWindow)
              QuitPreview = #True
           
          EndSelect
          
      EndSelect
  
    Until QuitPreview = #True
    
    CloseDatabase(PrintDB)
    
  EndProcedure
 
  Procedure GetPrinterInfo()
    
    Define printer_DC.l 
    
    CompilerSelect #PB_Compiler_OS
    
      CompilerCase   #PB_OS_MacOS
      
        ;The vectordrawing functions print correctly on the MAC so simply set all to zero
        Printer\Width = 0
        Printer\Height = 0
        Printer\TopPrinterMargin = 0
        Printer\LeftPrinterMargin = 0
        Printer\BottomPrinterMargin = 0
        Printer\RightPrinterMargin = 0

      CompilerCase   #PB_OS_Linux   
      
        ;Not Defined Yet
      
      CompilerCase   #PB_OS_Windows   
      
        Define HDPmm.d
        Define VDPmm.d
        
        printer_DC = StartDrawing(PrinterOutput())

        If printer_DC
          HDPmm = GetDeviceCaps_(printer_DC,#LOGPIXELSX) / 25.4
          VDPmm = GetDeviceCaps_(printer_DC,#LOGPIXELSY) / 25.4
          Printer\Width = GetDeviceCaps_(printer_DC,#PHYSICALWIDTH) / HDPmm
          Printer\Height = GetDeviceCaps_(printer_DC,#PHYSICALHEIGHT) / VDPmm
          Printer\TopPrinterMargin = GetDeviceCaps_(printer_DC,#PHYSICALOFFSETY) / VDPmm
          Printer\LeftPrinterMargin = GetDeviceCaps_(printer_DC,#PHYSICALOFFSETX) / HDPmm
          Printer\BottomPrinterMargin = 0
          Printer\RightPrinterMargin = 0
        EndIf

        StopDrawing()
      
    CompilerEndSelect
   
EndProcedure
  
  Procedure.f GettextWidthmm(text.s,FName.s,FSize.f)
    
    Define TextSize.f
    
    LoadFont(0,FName, FSize)    ;Load Font In Points
    TextSize = FSize * 0.352777778 ;Convert Font Points To mm
    VectorFont(FontID(0), TextSize ) ;Use Font In mm Size
    ProcedureReturn VectorTextWidth(text,#PB_VectorText_Visible) ;Width of text In mm

  EndProcedure
  
  Procedure.f GettextHeightmm(text.s,FName.s,FSize.f)
    
    Define TextSize.f 
    
    LoadFont(0,FName, FSize)    ;Load Font In Points
    TextSize = FSize * 0.352777778 ;Convert Font Points To mm
    VectorFont(FontID(0), TextSize)  ;Use Font In mm Size
    ProcedureReturn VectorTextHeight(text,#PB_VectorText_Visible) ;Height of text In mm

  EndProcedure 
  
  Procedure ShowPage(PageID)
    
    Define x1.i,y1.i,x2.i,y2.i,Width.i,FontSize.i,PrintImage.i,Left.i,Top.i
    Define TextSize.f    
    Define Criteria.s,TextImage.s,Font.s
    
    ;Open Print Job
    ;OpenPrintDB()
    
    ;Get Page Detail
    Criteria = "SELECT * FROM Pages WHERE PageNumber = " + Str(CurrentPage) + ";"
    DatabaseQuery(PrintDB,Criteria)    
    FirstDatabaseRow(PrintDB)
    ;Process Page Setup Commands
    PageOrientation = GetDatabaseLong(PrintDB,DatabaseColumnIndex(PrintDB,"Orientation"))
    FinishDatabaseQuery(PrintDB)
    
    ;Get Page Content
    Criteria = "SELECT * FROM Content WHERE PageNumber = " + Str(CurrentPage) + ";"
    DatabaseQuery(PrintDB,Criteria)

    StartVectorDrawing(ImageVectorOutput(PreviewImage))
    
    ;Clear Page Image
    DrawVectorImage(ImageID(ClearImage))

    ;If Printer and Page orientation different rotate
    If PageOrientation <> PrinterOrientation
      RotateCoordinates(0 , 0 , -90 )
      TranslateCoordinates( -ImageHeight(PreviewImage) , 0 ) 
    EndIf
    
    While NextDatabaseRow(PrintDB)

      ;Get all content variables
      x1 =  GetDatabaseLong(PrintDB,DatabaseColumnIndex(PrintDB,"x1"))
      y1 =  GetDatabaseLong(PrintDB,DatabaseColumnIndex(PrintDB,"y1"))          
      x2 =  GetDatabaseLong(PrintDB,DatabaseColumnIndex(PrintDB,"x2"))
      y2 =  GetDatabaseLong(PrintDB,DatabaseColumnIndex(PrintDB,"y2"))
      Width =  GetDatabaseLong(PrintDB,DatabaseColumnIndex(PrintDB,"Width"))        
      TextImage = GetDatabaseString(PrintDB,DatabaseColumnIndex(PrintDB,"TextOrImage"))
      Font = GetDatabaseString(PrintDB,DatabaseColumnIndex(PrintDB,"Font")) 
      FontSize = GetDatabaseLong(PrintDB,DatabaseColumnIndex(PrintDB,"FontSize"))
      
      ;Process Draw Page Content Commands
      Select GetDatabaseString(PrintDB,DatabaseColumnIndex(PrintDB,"Type"))
          
        Case "Line"

         MovePathCursor(x1 * GraphicScale.f, y1 * GraphicScale.f)
        
         AddPathLine(x2 * GraphicScale.f, y2 * GraphicScale.f, #PB_Path_Default)
        
         VectorSourceColor(RGBA(0, 0, 0, 255))
        
         StrokePath(Width * GraphicScale.f, #PB_Path_RoundCorner)       
        
       Case "Box"
         
         AddPathBox(x1 * GraphicScale.f, y1 * GraphicScale.f, (x2 - x1) * GraphicScale.f, (y2 - y1) * GraphicScale.f)

         VectorSourceColor(RGBA(255, 0, 0, 255))
    
         StrokePath(Width * GraphicScale.f)
         
       Case "Image"
         
         PrintImage = LoadImage(#PB_Any,GetCurrentDirectory() + PrintJob + "\" + TextImage) 
         MovePathCursor(x1 * GraphicScale.f, y1 * GraphicScale.f)
 
         DrawVectorImage(ImageID(PrintImage),100,x2 * GraphicScale.f,y2 * GraphicScale.f)
         
        Case "Text"
         

          LoadFont(0, Font , FontSize )
          TextSize = FontSize * 0.352777778 ;Convert Font Points To mm
          VectorFont(FontID(0), TextSize)
          VectorSourceColor(RGBA(0, 0, 0, 255))

          MovePathCursor(x1, y1)
          DrawVectorText(TextImage)      
         
     EndSelect ;Element Type  
        
    Wend
    FinishDatabaseQuery(PrintDB)
    StopVectorDrawing()
    ;CloseDatabase(PrintDB)
    
    ;Show Image Centred
    SetGadgetState(#imgPreview, ImageID(PreviewImage))  
    Left  = (540 - GadgetWidth(#imgPreview)) /2
    Top =  ((500-GadgetHeight(#imgPreview)) /2 ) + 30
    ResizeGadget(#imgPreview,Left,Top,#PB_Ignore,#PB_Ignore)
        
  EndProcedure
    
  Procedure Open(JobName.s,Mode.i = #Preview)
    
    ;Select Printer And Paper Etc
    If PrintRequester()
      
      ;Get Page Width,Height And Margins
      GetPrinterInfo()
      
      PrintJob = JobName
      PrintMode = Mode
      
      If Printer\Height > Printer\Width
        PrinterOrientation = #Portrait
      Else
        PrinterOrientation = #Landscape 
      EndIf
      
      ;Create Print Job Database
      PageNo = 0
      CurrentPage = 0
      CreateDirectory(GetCurrentDirectory() + PrintJob)
      OpenPrintDB()
      
      ;New PrintJob So Clear Old Job
      DatabaseUpdate(PrintDB,"DELETE FROM Pages")
      DatabaseUpdate(PrintDB,"DELETE FROM Content")      
      DatabaseUpdate(PrintDB,"VACUUM")
     
    EndIf    
    
  EndProcedure
  
  Procedure AddPage(Orientation.i)
    
    Define Criteria.s
    
    PageNo = PageNo + 1
    
    Criteria = "INSERT INTO Pages (PageNumber,Orientation)"
    Criteria = Criteria + " VALUES (" + Str(PageNo) + "," + Str(Orientation) + ")"
    DatabaseUpdate(PrintDB,Criteria) 
    
  EndProcedure
  
  Procedure PrintLine(X1,Y1,X2,Y2,Width)
    
    Define Criteria.s
      
    Criteria = "INSERT INTO Content (PageNumber,Type,x1,y1,x2,y2,Width,Font,FontSize,TextOrImage,Colour,Flags)"
    Criteria = Criteria + " VALUES (" + Str(PageNo) +",'Line'," + Str(X1) + "," +Str(Y1) + "," + Str(X2) + "," + Str(Y2) + "," + Str(Width) + ",'None',0,'None',0,0);"
    DatabaseUpdate(PrintDB,Criteria)  

    
    ;Else
      
      ;Direct To Printer
    ;  Startx = Startx - Printer\LeftPrinterMargin
    ;  Starty = Starty - Printer\TopPrinterMargin
    ;  Endx = Endx - Printer\LeftPrinterMargin
    ;  Endy = Endy - Printer\TopPrinterMargin  
 ;     MovePathCursor(Startx, Starty)
        
 ;     AddPathLine(Endx, Endy, #PB_Path_Default)
        
 ;     VectorSourceColor(RGBA(0, 0, 0, 255))
        
 ;     StrokePath(LineWidth,#PB_Path_RoundCorner)

   ; EndIf

  EndProcedure
 
  Procedure PrintBox(X1.i,Y1.i,X2.i,Y2.i,Width.i)
    
    Define Criteria.s
      
    Criteria = "INSERT INTO Content (PageNumber,Type,x1,y1,x2,y2,Width,Font,FontSize,TextOrImage,Colour,Flags)"
    Criteria = Criteria + " VALUES (" + Str(PageNo) +",'Box'," + Str(X1) + "," +Str(Y1) + "," + Str(X2) + "," + Str(Y2) + "," + Str(Width) + ",'None',0,'None',0,0);"
    DatabaseUpdate(PrintDB,Criteria)  
    
      
      ;Direct To Printer
 ;     Topx = Topx - PrinterInfo\LeftMargin
 ;     Topy = Topy - PrinterInfo\TopMargin
 ;     Bottomx = Bottomx - PrinterInfo\LeftMargin
 ;     Bottomy = Bottomy - PrinterInfo\TopMargin     
 ;     AddPathBox(Topx, Topy , (Bottomx - Topx), (Bottomy - Topy))

 ;     VectorSourceColor(RGBA(255, 0, 0, 255))
            
 ;     StrokePath(LineWidth)
  
  ;EndIf 
    
  EndProcedure
  
  Procedure PrintText(X1.i,Y1.i,Font.s,Size.i,Text.s)
    
    Define Criteria.s
      
    Criteria = "INSERT INTO Content (PageNumber,Type,x1,y1,x2,y2,Width,Font,FontSize,TextOrImage,Colour,Flags)"
    Criteria = Criteria + " VALUES (" + Str(PageNo) +",'Text'," + Str(X1) + "," +Str(Y1) + ",0,0,0,'" + Font + "'," + Str(Size) + ",'" + Text +"',0,0);"
    DatabaseUpdate(PrintDB,Criteria) 

  EndProcedure

  Procedure PrintImage(Image.s,X1.i,Y1.i,X2.i,Y2)
    
    Define Criteria.s,ImageFile.s,CopyTo.s
    
    ;Copy Image To Print Directory
    ImageFile = GetFilePart(Image)
    
    CopyTo = GetCurrentDirectory() + PrintJob + "\" + ImageFile

    CopyFile(Image,CopyTo)
    Criteria = "INSERT INTO Content (PageNumber,Type,x1,y1,x2,y2,Width,Font,FontSize,TextOrImage,Colour,Flags)"
    Criteria = Criteria + " VALUES (" + Str(PageNo) +",'Image'," + Str(X1) + "," + Str(Y1) + "," + Str(x2) + "," + Str(y2) + ",0,'None',0,'" + ImageFile +"',0,0);"
    DatabaseUpdate(PrintDB,Criteria) 
  
  EndProcedure

  Procedure Finished()
    
    Define iLoop.i
    
    TotalPages = PageNo
    
    If PrintMode = #NoPreview
      
      If SetPagesToPrint()
        StartPrinting("Tester") 
        For iLoop = 0 To ArraySize(PageRange()) - 1
          PrintPage(PageRange(iLoop))
        Next iLoop
        StopPrinting()
      EndIf
      CloseDatabase(PrintDB)
      
    Else
      ShowPreview()
    EndIf
        
  EndProcedure
  
  Procedure CDPrintEvents(Event)
    
    If event = #PB_Event_CloseWindow
      CloseWindow(PreviewWindow)
    EndIf
      
    If Event = #PB_Event_Gadget

      Select EventGadget()
        Case 66
          
          SetGadgetText(66, Str(GetGadgetState(66)))
          If GetGadgetState(66) > 0 And GetGadgetState(66) -1 <= PageNo.i
            ShowPage(GetGadgetState(66) -1)
          ElseIf GetGadgetState(66) < 1
            ;Show Last Page No or first page Number in gadget
            SetGadgetState(66,1)
          Else
            SetGadgetState(66,PageNo.i + 1 )
          EndIf
          
        EndSelect       
         
        EndIf
    
  EndProcedure

EndModule
; IDE Options = PureBasic 5.60 Beta 1 (Windows - x64)
; CursorPosition = 378
; FirstLine = 275
; Folding = bzg+
; EnableXP
; EnableUnicode