XIncludeFile "Tbl.pbi"
UseSQLiteDatabase()
Declare Exit()
Declare OpenMainForm()
Global DbName.s="DbTeste.sqlite"
If OpenDatabase(0,DbName,"","")=0
    MessageRequester("Error","Can't open database")
    End
EndIf
Procedure Exit()
    Tbl::Free(0)
    End
EndProcedure
Procedure OpenMainForm()
    Protected Flag=#PB_Window_SystemMenu|#PB_Window_ScreenCentered
    Protected HF
    ; Création de la table
    Tbl::Create(0,10,10,620,20,0,"localite","IDlocalite","Liste des localités")
    Tbl::AddColumn("Pays",200,"IDpays")
    Tbl::SetLink("pays","IDpays","nom")
    Tbl::EnableFilters()
    Tbl::AddColumn("Code postal",200,"code_postal")
    Tbl::AddColumn("Localité",200,"nom")
    Tbl::EnableColumnSearch()
    Tbl::SetOrderClause("ORDER BY pays.nom,localite.nom")
    HF=Tbl::GetTableHeight()+20
    OpenWindow(0,0,0,640,HF,"Teste",Flag)
    Tbl::Draw()
    BindEvent(#PB_Event_CloseWindow,@Exit())
EndProcedure
OpenMainForm()
Repeat:WaitWindowEvent():ForEver
; IDE Options = PureBasic 5.50 (Windows - x64)
; CursorPosition = 10
; Folding = -
; EnableXP