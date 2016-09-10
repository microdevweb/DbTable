;************************************************************************************************************************
; Author : MicrodevWeb
; Project Name : Pb_Table
; File Name : Tbl.pbi
; Module : Tbl
; Description : DataBaseTable 
; Version :  Béta 5.01
;************************************************************************************************************************
; TODO callback quand interversion des colonnes
; TODO Pouvoir replacer l'ordre des colonnes
; TODO modification des taille des colonnes par procédures

DeclareModule Tbl
    ;-* PUBLIC VARIABLE/LIST/MAP/CONSTANTE
    Enumeration 
        #Left
        #Right
        #Center
    EndEnumeration
    ;}
    ;-* PUBLIC DECLARATION
    Declare Create(Id,X,Y,Width,NumberLine,IdDb.i,TableName.s,IdTable.s,Title.s="")
    Declare GetTableHeight()
    Declare UseTable(IdTable)
    Declare AddColumn(Label.s,Width,DbColumnName.s="")
    Declare UseColumn(IdColumn)
    Declare Draw()
    Declare EnableColumnSearch(State.b=#True)
    Declare EnableOrderAsc()
    Declare EnableOrderDes()
    Declare SetColumnResizeCallback(*Callback)
    Declare SetLink(LinkedTable.s,StrangerId.s,StrangerColumn.s)
    Declare EnableFilters(State.b=#True)
    Declare SetCallbackToSelect(*Callback)
    Declare SetDoubleClickCallback(*Callback)
    Declare SetColumnAlignment(Alignment.i)
    Declare SetCalculteCallback(*Callback)
    Declare SetOrderClause(OrderClause.s)
    Declare Free(IdTable)
    ;}
EndDeclareModule
Module Tbl
    EnableExplicit
    UsePNGImageDecoder()
    ;-* PROTOTYPE
    Prototype.s proCalcul(id)
    ;}
    ;-* LOCAL VARIABLE/LIST/MAP/CONSTANTE
    ; Chargement des images
    Global DownArrow=CatchImage(#PB_Any,?DownArrow)
    Global UpArrow=CatchImage(#PB_Any,?UpArrow)
    Global  Filter=CatchImage(#PB_Any,?Filter)
    Global shearch=CatchImage(#PB_Any,?shearch)
    Global shearchOn=CatchImage(#PB_Any,?shearchOn)
    Global FilterOn=CatchImage(#PB_Any,?FilterOn)
    Global gMouseX,gMouseY,*ColumnLineHover=-1,OldMouseX,OldMouseY,DepX,DepY,NewX,NewY
    Global *ColumnShearchHover=-1,*ColumnFiltersHover=-1,*ColumnHover=-1,*LigneHover=-1
    Structure Color
        Bg.q
        Fg.q
    EndStructure
    Structure Column
        Order.i
        Label.s
        DbColumnName.s
        Widht.i
        FilterOn.b
        OrderOn.b
        ShearchOn.b
        MoveableOn.b
        ResizeOn.b
        OrderAscOn.b
        OrderDesOn.b
        *ResizeCallback
        LinkedTable.s
        StrangerColumn.s
        StrangerId.s
        Alignment.i
        Margin.i
        *CalculateCallback
        ShearchValue.s
        FiltersId.i
    EndStructure
    Structure Properties
        TableColors.Color
        HeaderColors.Color
        HeaderFont.i
        HeaderHeight.i
        PairLineColors.Color
        PairLineFont.i
        OddLineColors.Color
        OddLineFont.i
        SelectLineColors.Color
        SelectLineFont.i
        LineHeight.i
        ColumnTitleHeight.i
        ColumnTitleColor.Color
        ColumnTitleFont.i
        MinimumColumnWidth.i
        MinimumLineHeight.i
        FiltersDisableMesage.s
    EndStructure
    Structure Table
        IdDb.i
        IdCanvas.i
        IdImage.i
        IdScrollV.i
        IdScrollH.i
        NumberLine.i
        Height.i
        Width.i
        X.i
        Y.i
        HeaderTitle.s
        myProperties.Properties
        TableName.s
        IdTable.s
        List myColumn.Column()
        req.s
        NbRecord.i
        IdLigneSelected.i
        TotalWidthColumn.i
        OrderClause.s
        *SelectCallback
        *DoubleClickCallback
        ShearchField.i
        myWindow.i
        WhereClause.s
        ShearchWindow.i
        FiltersCombo.i
        FiltersClause.s
    EndStructure
    Structure DataColumn
        Type.i
        Value.s
    EndStructure
    Structure DataLine
        Id.i
        List myColumn.DataColumn()
    EndStructure
    Global NewMap myTable.Table()
    Global NewList  myDataLine.DataLine()
    ;}
    ;-* LOCAL DECLARATION
    Declare CreateProperties()
    Declare CalculTableHeight()
    Declare Event()
    Declare DrawTempImage()
    Declare DrawCanvas()
    Declare DrawColumnTitle()
    Declare DrawLine()
    Declare HoverColumnLine()
    Declare DisplayPreviewColumnLine()
    Declare DrawImageToCanvas()
    Declare SaveNewSizeColumn()
    Declare ManageScrollbar()
    Declare EventScrollH()
    Declare HoverColumnShearch()
    Declare HoverColumnFilters()
    Declare  HoverColumn()
    Declare MovecolumnToRight()
    Declare MovecolumnToLeft()
    Declare ActiveSortToColumn()
    Declare ManageDataScroll()
    Declare MakeRequest()
    Declare DrawData()
    Declare EventScrollV()
    Declare HoverLigne(NotSelected.b=#True)
    Declare ActiveShearch()
    Declare DisableShearchField()
    Declare SetShearhClause()
    Declare ErazeShearch()
    Declare ActiveFilters()
    Declare FillFiltersCombo()
    Declare SetFiltersClause()
    Declare ErazeFilter()
    Declare.s MakeCountRequest()
    ;}
    ;-* PRIVATE PROCEDURE
    Procedure CreateProperties()
        With myTable()\myProperties
            ; Couleurs de la tabler
            \TableColors\Bg=$FF737373
            \TableColors\Fg=$FFB5B5B5
            ; Entête de la table
            \HeaderColors\Bg=$FF737373
            \HeaderColors\Fg=$FFFFFFFF
            \HeaderFont=LoadFont(#PB_Any,"Arial",11,#PB_Font_HighQuality)
            \HeaderHeight=40
            ; Les lignes paires
            \PairLineColors\Bg=$FF008CFF
            \PairLineColors\Fg=$FF000000
            \PairLineFont=LoadFont(#PB_Any,"Arial",10,#PB_Font_HighQuality)
            ; Les lignes impaires
            \OddLineColors\Bg=$FFC2E3FF
            \OddLineColors\Fg=$FF000000
            \OddLineFont=LoadFont(#PB_Any,"Arial",10,#PB_Font_HighQuality)
            ; Les lignes sélectionnées
            \SelectLineColors\Bg=$FFCD0000
            \SelectLineColors\Fg=$FFFFFFFF
            \SelectLineFont=LoadFont(#PB_Any,"Arial",10,#PB_Font_HighQuality|#PB_Font_Bold)
            ; La hauteur de la ligne
            \LineHeight=30
            ; Le titre des colonnes
            \ColumnTitleHeight=30
            \ColumnTitleColor\Bg=#PB_Ignore
            \ColumnTitleColor\Fg=$FF000000
            \ColumnTitleFont=LoadFont(#PB_Any,"Arial",10,#PB_Font_HighQuality|#PB_Font_Bold)
            \MinimumColumnWidth=20
            \MinimumLineHeight=15
            ; Message quand le filtre n'est pas actif
            \FiltersDisableMesage="Pas de filtre"
        EndWith
    EndProcedure
    Procedure CalculTableHeight()
        With myTable()
            If \HeaderTitle<>""
                \Height=\myProperties\HeaderHeight
            Else
                \Height=0
            EndIf
            \Height+(\myProperties\LineHeight*\NumberLine)
            \Height+\myProperties\ColumnTitleHeight
        EndWith
    EndProcedure
    Procedure Event()
        Static ClicOn.b=#False
        Protected ScrollValue
        ; Pointe dur la bonne table
        Protected Id=GetGadgetData(EventGadget())
        If FindMapElement(myTable(),Str(Id))=0
            MessageRequester("Event Error","This table Id "+Str(Id)+" do not exists",#PB_MessageRequester_Error)
            ProcedureReturn 
        EndIf
        
        With myTable()
            ; Relève la position de la souris
            gMouseX=GetGadgetAttribute(\IdCanvas,#PB_Canvas_MouseX)
            gMouseY=GetGadgetAttribute(\IdCanvas,#PB_Canvas_MouseY)
            Select EventType()
                Case #PB_EventType_MouseEnter
                    If \ShearchWindow=-1
                        SetActiveWindow(\myWindow)
                        SetActiveGadget(\IdCanvas)
                    EndIf
                Case #PB_EventType_MouseMove
                    If Not ClicOn ; Si le bouton gauche n'est pas enfoncé
                        ; Par défaut on n'est pas sur une ligne de colonne
                        *ColumnLineHover=-1
                        ; Par défaut on n'est pas sur le bt cherche
                        *ColumnShearchHover=-1
                        ; Par défaut on n'est pas sur le bt filtre
                        *ColumnFiltersHover=-1
                        ; Par défaut on n'est pas sur une colonne
                        *ColumnHover=-1
                        ; Par défaut on n'est pas sur une ligne de table
                        *LigneHover=-1
                        ; Regarde si sur une ligne de colonne
                        If HoverColumnLine():ProcedureReturn :EndIf
                        ; Regarde si sur un bt de recherche
                        If HoverColumnShearch():ProcedureReturn  :EndIf
                        ; Regarde si sur un bt de filtre
                        If HoverColumnFilters():ProcedureReturn  :EndIf
                        ; Regarde si sur la colonne
                        If HoverColumn():ProcedureReturn :EndIf
                        ; Regarde si sur une ligne de la table
                        If HoverLigne():ProcedureReturn :EndIf
                        SetGadgetAttribute(\IdCanvas,#PB_Canvas_Cursor,#PB_Cursor_Default)    
                    Else ; Le bt gauche est enfoncé
                         ; On calcul les déplacement
                        DepX=gMouseX-OldMouseX
                        DepY=gMouseY-OldMouseY
                        ; Si sur une ligne de colonne
                        If *ColumnLineHover>-1
                            DisplayPreviewColumnLine()
                        EndIf
                        ; Si sur une colonne et déplacement à droite
                        If *ColumnHover>-1 And DepX>20
                            MovecolumnToRight()
                            ClicOn=#False
                        EndIf
                        ; Si sur une colonne et déplacement à gauche
                        If *ColumnHover>-1 And DepX<-20
                            MovecolumnToLeft()
                            ClicOn=#False
                        EndIf
                    EndIf
                Case #PB_EventType_LeftButtonDown
                    If \ShearchWindow>-1
                        CloseWindow(\ShearchWindow)
                        \ShearchWindow=-1
                        SetActiveWindow(\myWindow)
                        SetActiveGadget(\IdCanvas)
;                         UseGadgetList(\myWindow)
                    EndIf
                    ; Au premier click on mémorise la position de la souris
                    If Not ClicOn
                        OldMouseX=gMouseX
                        OldMouseY=gMouseY
                    EndIf
                    ; Si sur une ligne de table
                    If *LigneHover>-1
                        ; Sélectionne la ligne
                        ChangeCurrentElement(myDataLine(),*LigneHover)
                        \IdLigneSelected=myDataLine()\Id
                        ; Si un callback est renseigné on l'appelle
                        If \SelectCallback>-1
                            CallFunctionFast(\SelectCallback,\IdLigneSelected)
                        EndIf
                        Draw()
                        ProcedureReturn 
                    EndIf
                    ; Si sur le bt de recherche
                    If *ColumnShearchHover>-1
                        ActiveShearch()
                        ProcedureReturn 
                    EndIf
                    ; Si sur le bt filtre
                    If *ColumnFiltersHover>-1
                        ActiveFilters()
                        ProcedureReturn 
                    EndIf
                    ClicOn=#True
                Case #PB_EventType_LeftButtonUp
                    If *ColumnLineHover>-1
                        SaveNewSizeColumn() ; Sauve la taille de la colone
                    EndIf
                    If *ColumnHover And ClicOn
                        ActiveSortToColumn()
                    EndIf
                    ClicOn=#False
                Case #PB_EventType_MouseWheel
                    ; Si touche control déplacement ascensseur vertical
                    If GetGadgetAttribute(\IdCanvas,#PB_Canvas_Modifiers)=#PB_Canvas_Control 
                        If IsGadget(\IdScrollH)
                            ScrollValue= GetGadgetState(\IdScrollH)
                            If GetGadgetAttribute(\IdCanvas,#PB_Canvas_WheelDelta)=1
                                If ScrollValue>0
                                    SetGadgetState(\IdScrollH,ScrollValue-1)
                                EndIf
                            Else
                                If ScrollValue<GetGadgetAttribute(\IdScrollH,#PB_ScrollBar_Maximum)
                                    SetGadgetState(\IdScrollH,ScrollValue+1)
                                EndIf
                            EndIf
                            EventScrollH()
                        EndIf
                    Else
                        If IsGadget(\IdScrollV)
                            ScrollValue= GetGadgetState(\IdScrollV)
                            If GetGadgetAttribute(\IdCanvas,#PB_Canvas_WheelDelta)=-1
                                If ScrollValue<GetGadgetAttribute(\IdScrollV,#PB_ScrollBar_Maximum)
                                    SetGadgetState(\IdScrollV,ScrollValue+1)
                                EndIf
                            Else
                                If ScrollValue>0
                                    SetGadgetState(\IdScrollV,ScrollValue-1)
                                EndIf
                            EndIf
                            EventScrollV()
                        EndIf
                    EndIf
                Case #PB_EventType_LeftDoubleClick
                    ; Si une procédure en cas de double clique à été renseignée
                    If \DoubleClickCallback>-1
                        If HoverLigne(#False)
                            ChangeCurrentElement(myDataLine(),*LigneHover)
                            CallCFunctionFast(\DoubleClickCallback,myDataLine()\Id)
                        EndIf
                    EndIf
            EndSelect
        EndWith
    EndProcedure
    Procedure DrawTempImage()
        Protected W,H,WD,M=4
        With myTable()
            ; Calcul de taille de l'image temporaire
            ; La largeur
            ForEach \myColumn()
                W+\myColumn()\Widht
            Next
            \TotalWidthColumn=W
            H=\NumberLine*\myProperties\LineHeight
            H+\myProperties\ColumnTitleHeight
            If W<(\Width-(M*2))
                WD=(\Width-(M*2))
            Else
                WD=W
            EndIf
            ; Création de l'image si elle n'existe pas
            If IsImage(\IdImage)=0
                \IdImage=CreateImage(#PB_Any,WD,H)
            EndIf
            ; Redimentionne l'image si nécessaire
            If ImageWidth(\IdImage)<>WD
                ResizeImage(\IdImage,WD,GadgetHeight(\IdCanvas))
            EndIf
            StartVectorDrawing(ImageVectorOutput(\IdImage))
            ; Efface l'image avec le font de la table
            VectorSourceColor(\myProperties\TableColors\Bg)
            FillVectorOutput()
            ; Dessin des lignes
            DrawLine()
            ; Dessine le titre des colonnes
            DrawColumnTitle()
            ; Dessin des data
            DrawData()
            StopVectorDrawing()
        EndWith
    EndProcedure
    Procedure DrawCanvas()
        Protected W,H,M=4,X,Y,img.i
        With myTable()
            StartVectorDrawing(CanvasVectorOutput(\IdCanvas))
            ; Remplisage de la table avec la couleur de fond
            VectorSourceColor(\myProperties\TableColors\Bg)
             FillVectorOutput()
            ; Dessin d'un cadre autour de la table
            AddPathBox(0,0,\Width,\Height)
            VectorSourceColor(\myProperties\TableColors\Fg)
            StrokePath(M)
            ; Si un titre d'entête est renseigné on dessine l'entête
            If \HeaderTitle<>""
                ; Dessin du cadre
                W=GadgetWidth(\IdCanvas)-(M*2)
                H=\myProperties\HeaderHeight-M
                X=M
                Y=M
                AddPathBox(0,0,\Width,\Height)
                ; Couleur de fond de l'entête
                VectorSourceColor(\myProperties\HeaderColors\Bg)
                FillPath()
                ; Titre de l'entête
                VectorFont(FontID(\myProperties\HeaderFont))
                VectorSourceColor(\myProperties\HeaderColors\Fg)
                Y=M+(H/2)
                Y-(VectorParagraphHeight(\HeaderTitle,W,H)/2)
                MovePathCursor(X,Y)
                DrawVectorParagraph(\HeaderTitle,W,H,#PB_VectorParagraph_Center)
            EndIf
            ; Dessin de l'image
            DrawImageToCanvas()
            StopVectorDrawing()
        EndWith
    EndProcedure
    Procedure DrawColumnTitle()
        Protected X1,X2,Y1,Y2,X,XT,Y,Txt.s,ColumnWidth,ImgSize,XD
        With myTable()
            X1=0
            X2=X1
            Y1=0
            Y2=\myProperties\ColumnTitleHeight
            If \myProperties\ColumnTitleColor\Bg=#PB_Ignore
                VectorSourceLinearGradient(X1,X2,Y1,Y2)
                VectorSourceGradientColor($FFC4C4C4,0)
                VectorSourceGradientColor($FFC4C4C4,0.7)
                VectorSourceGradientColor($FF909090,1)
            Else
                VectorSourceColor(\myProperties\ColumnTitleColor\Bg)
            EndIf
            AddPathBox(0,0,ImageWidth(\IdImage),\myProperties\ColumnTitleHeight)
            FillPath()
        EndWith
        ; Dessine le titre des colonnes
        ImgSize=myTable()\myProperties\ColumnTitleHeight*0.5
        VectorFont(FontID(myTable()\myProperties\ColumnTitleFont))
        VectorSourceColor(myTable()\myProperties\ColumnTitleColor\Fg)
        Y=(myTable()\myProperties\ColumnTitleHeight/2)-(VectorTextHeight("W")/2)
        With myTable()\myColumn()
            ; Trie la liste sur l'ordre
            SortStructuredList(myTable()\myColumn(),#PB_Sort_Ascending,OffsetOf(Column\Order),TypeOf(Column\Order))
            ForEach myTable()\myColumn()
                XD=X
                ; Calcul de la taille de la colonne
                ColumnWidth=\Widht-(8)
                ; Dessin de l'icone shearch si actif
                If \ShearchOn
                    MovePathCursor(X+2,Y)
                    If \ShearchValue=""
                        DrawVectorImage(ImageID(shearch),255,ImgSize,ImgSize)
                    Else
                        DrawVectorImage(ImageID(shearchOn),255,ImgSize,ImgSize)
                    EndIf
                EndIf
                ; Dessin de l'icone Filters si actif
                If \FilterOn
                    MovePathCursor(X+2,Y)
                    If \FiltersId>-1
                        DrawVectorImage(ImageID(FilterOn),255,ImgSize,ImgSize)
                    Else
                        DrawVectorImage(ImageID(Filter),255,ImgSize,ImgSize)
                    EndIf
                EndIf
                If \OrderAscOn Or \OrderDesOn
                    ColumnWidth-(ImgSize+4)
                EndIf
                If \ShearchOn Or \FilterOn
                    ColumnWidth-(ImgSize+4)
                    XD+(ImgSize+4)
                EndIf
                ; Concatene le texte
                Txt=\Label
                While VectorTextWidth(Txt)>ColumnWidth
                    If Len(Txt)<4
                        Txt=""
                        Break
                    EndIf
                    Txt=Left(Txt,Len(Txt)-4)
                    Txt+"..."
                Wend
                ; Centrage du texte    
                XT=XD+(ColumnWidth)/2
                XT-(VectorTextWidth(Txt)/2)
                MovePathCursor(XT,Y)
                DrawVectorText(Txt)
                ; Dessin de l'icone ordre si actif
                If \OrderDesOn
                    MovePathCursor((X+\Widht)-ImgSize,Y)
                    DrawVectorImage(ImageID(UpArrow),255,ImgSize,ImgSize)
                EndIf
                If \OrderAscOn
                    MovePathCursor((X+\Widht)-(ImgSize+2),Y)
                    DrawVectorImage(ImageID(DownArrow),255,ImgSize,ImgSize)
                EndIf
                ; Dessin de la ligne de colonne
                VectorSourceColor($FF000000)
                MovePathCursor(X+\Widht,0)
                AddPathLine(X+\Widht,ImageHeight(myTable()\IdImage))
                StrokePath(1.5)
                X+\Widht
            Next
        EndWith
    EndProcedure
    Procedure DrawLine()
        Protected Y,N,Color,W,H
        With myTable()
            Y=\myProperties\ColumnTitleHeight
            ForEach \myColumn()
                W+\myColumn()\Widht
            Next
            H=\myProperties\LineHeight
            For N=1 To \NumberLine
                If N & 1 ; ligne impair
                    Color=\myProperties\OddLineColors\Bg
                Else
                    Color=\myProperties\PairLineColors\Bg
                EndIf
                VectorSourceColor(Color)
                MovePathCursor(0,Y)
                AddPathBox(0,Y,W,H)
                FillPath(#PB_Path_Preserve)
                VectorSourceColor($FF000000)
                StrokePath(1.5)
                Y+H
            Next
        EndWith
    EndProcedure
    Procedure HoverColumnLine()
        Protected Y1,Y2,X,X1,X2
        With myTable()
            ; Si une titre d'entête on regarde sous le titre
            If \HeaderTitle<>""
                Y1=\myProperties\HeaderHeight
            EndIf
            Y2=GadgetHeight(\IdCanvas)
            X=0
            ; Si l'acsenseur horizontal est actif on prend sa valeur en compte
            If IsGadget(\IdScrollH)
                X-GetGadgetState(\IdScrollH)
            EndIf
             ; Trie la liste sur l'ordre
            SortStructuredList(myTable()\myColumn(),#PB_Sort_Ascending,OffsetOf(Column\Order),TypeOf(Column\Order))
            ForEach \myColumn()
                X+\myColumn()\Widht
                X1=X-2
                X2=X1+4
                If (gMouseY>=Y1 And gMouseY<=Y2) And (gMouseX>=X1 And gMouseX<=X2)
                    SetGadgetAttribute(\IdCanvas,#PB_Canvas_Cursor,#PB_Cursor_LeftRight)
                    *ColumnLineHover=@\myColumn()
                    ProcedureReturn #True
                EndIf
            Next
            ProcedureReturn #False
        EndWith
    EndProcedure
    Procedure DisplayPreviewColumnLine()
        ; Affiche la position de la nouvelle taille de la colonne
        Protected X,Y,H
        With myTable()
            ; Si il y a un titre d'entête on dessine en dessous
            H=\Height
            Y=4
            If \HeaderTitle<>""
                Y+\myProperties\HeaderHeight
                H-\myProperties\HeaderHeight
            EndIf
            StartVectorDrawing(CanvasVectorOutput(\IdCanvas))
            ; On efface avec l'image de la table
            DrawImageToCanvas()
            ; Dessin de la ligne
            X=4
            ; Si l'ascensseur horisontal est actif on le prend en compte
            If IsGadget(\IdScrollH)
                X-GetGadgetState(\IdScrollH)
            EndIf
            ; Parcour de toute les colonne pour le calcul de la position
            ForEach \myColumn()
                X+\myColumn()\Widht
                If @\myColumn()=*ColumnLineHover
                    NewX=\myColumn()\Widht
                    Break
                EndIf
            Next
            ; Si la colonne est plus grande que la taille minimum
            If NewX+DepX>\myProperties\MinimumColumnWidth
                X+DepX
                NewX+DepX
                SetGadgetAttribute(\IdCanvas,#PB_Canvas_Cursor,#PB_Cursor_LeftRight)
            Else
                SetGadgetAttribute(\IdCanvas,#PB_Canvas_Cursor,#PB_Cursor_Denied)
            EndIf
            MovePathCursor(X,Y)
            AddPathLine(X,Y+H)
            VectorSourceColor($FF0000FF)
            DotPath(3,8)
            StopVectorDrawing()
        EndWith
    EndProcedure
    Procedure DrawImageToCanvas()
        Protected X,Y,M=4,W,H,img,XG
        ; Dessin de l'image 
        With myTable()
            X=M
            If \HeaderTitle<>""
                Y=M+\myProperties\HeaderHeight
            EndIf
            ; Si l'image est plus grande que le canvas sans les marges
            If ImageWidth(\IdImage)>(GadgetWidth(\IdCanvas)-(M*2))
                W=(GadgetWidth(\IdCanvas)-(M*2))
            Else
                W=ImageWidth(\IdImage)
            EndIf
            H=ImageHeight(\IdImage)
            ; Découpe de l'image
            ; Si l'ascenseur horizontal est actif on prend en compte la valeur de ce dernier
            If IsGadget(\IdScrollH)
                XG=GetGadgetState(\IdScrollH)
            EndIf
            img=GrabImage(\IdImage,#PB_Any,XG,0,W,H)
            MovePathCursor(X,Y)
            DrawVectorImage(ImageID(img))
            FreeImage(img)
        EndWith
    EndProcedure
    Procedure SaveNewSizeColumn()
        ; Sauve la nouvelle taille de la colonne
        With myTable()
            ChangeCurrentElement(\myColumn(),*ColumnLineHover)
            \myColumn()\Widht=NewX
            ; Si une procédure callback a été renseignée on l'appelle
            If \myColumn()\ResizeCallback>-1
                CallFunctionFast(\myColumn()\ResizeCallback,ListIndex(\myColumn()),\myColumn()\Widht)
            EndIf
            ; Redesine l'image temporaire
            DrawTempImage()
            ; Réaffiche l'image
            Draw()
        EndWith
    EndProcedure
    Procedure ManageScrollbar()
        UseGadgetList(WindowID(myTable()\myWindow))
        ; Regarde si les ascenseurs sont nécessaire
        ; L'ascenseur horizontal
        Protected TotalWidth,Y,Max,X
        With myTable()
            ForEach \myColumn()
                TotalWidth+\myColumn()\Widht
            Next
            ; Si la largeur total des colonnes est plus grande que la largeur du canvas - les marges
            If TotalWidth>(GadgetWidth(myTable()\IdCanvas)-8)
                ; Si l'ascensseur n'existe pas déjà
                If IsGadget(\IdScrollH)=0
                    ; Retire une ligne
                    \NumberLine-1
                    ; Redimentionne le canvas
                    ResizeGadget(\IdCanvas,#PB_Ignore,#PB_Ignore,#PB_Ignore,\Height-\myProperties\LineHeight)
                    X=GadgetX(\IdCanvas)
                    Y=GadgetY(\IdCanvas)+(\Height-\myProperties\LineHeight)
                    ; Mise en place du scrollbar
                    Max=TotalWidth-(GadgetWidth(myTable()\IdCanvas)-10)
                    \IdScrollH=ScrollBarGadget(#PB_Any,X,Y,(GadgetWidth(myTable()\IdCanvas)-8),\myProperties\LineHeight,0,Max,0)
                    SetGadgetData(\IdScrollH,Val(MapKey(myTable())))
                    ; Mise en place d'un callback
                    BindGadgetEvent(\IdScrollH,@EventScrollH())
                EndIf
;                 SetGadgetAttribute(\IdScrollH,#PB_ScrollBar_PageLength,10)
            Else
                ; Si l'ascenseur horizontal est actif 
                If IsGadget(\IdScrollH)
                    ; Ajoute un ligne
                    \NumberLine+1
                    ; Redimentionne le canvas
                    ResizeGadget(\IdCanvas,#PB_Ignore,#PB_Ignore,#PB_Ignore,\Height)
                    ; Supprime l'ascenseur
                    FreeGadget(\IdScrollH)
                EndIf
            EndIf
            ; Gestion de l'ascenseur vertical
            ManageDataScroll()
        EndWith
    EndProcedure
    Procedure EventScrollH()
        With myTable()
            FindMapElement(myTable(),Str(GetGadgetData(EventGadget())))
            StartVectorDrawing(CanvasVectorOutput(\IdCanvas))
            DrawImageToCanvas()
            StopVectorDrawing()
        EndWith
    EndProcedure
    Procedure HoverColumnShearch()
        ; Regarde si la souris est sur une bt de recherche
        With myTable()
            Protected ImgSize=\myProperties\HeaderHeight*0.5
            Protected X,X1,X2,Y1,Y2
            ; Si un titre d'entête on regarde en dessous
            If \HeaderTitle<>""
                Y1=\myProperties\HeaderHeight
            EndIf
            Y2=Y1+\myProperties\ColumnTitleHeight
            ; Si l'ascensseur horizontal est actif on le prend en compte
            If IsGadget(\IdScrollH)
                X-GetGadgetState(\IdScrollH)
            EndIf
             ; Trie la liste sur l'ordre
            SortStructuredList(myTable()\myColumn(),#PB_Sort_Ascending,OffsetOf(Column\Order),TypeOf(Column\Order))
            ForEach \myColumn()
                If \myColumn()\ShearchOn
                    X1=X+2
                    X2=X1+ImgSize
                    If (gMouseY>=Y1 And gMouseY<=Y2) And (gMouseX>=X1 And gMouseX<=X2)
                        SetGadgetAttribute(\IdCanvas,#PB_Canvas_Cursor,#PB_Cursor_Hand)
                        *ColumnShearchHover=@\myColumn()
                        ProcedureReturn #True
                    EndIf
                EndIf
                X+\myColumn()\Widht
            Next
            ProcedureReturn #False
        EndWith
    EndProcedure
    Procedure HoverColumnFilters()
        ; Regarde si la souris est sur une bt de recherche
        With myTable()
            Protected ImgSize=\myProperties\HeaderHeight*0.5
            Protected X,X1,X2,Y1,Y2
            ; Si un titre d'entête on regarde en dessous
            If \HeaderTitle<>""
                Y1=\myProperties\HeaderHeight
            EndIf
            Y2=Y1+\myProperties\ColumnTitleHeight
            ; Si l'ascensseur horizontal est actif on le prend en compte
            If IsGadget(\IdScrollH)
                X-GetGadgetState(\IdScrollH)
            EndIf
             ; Trie la liste sur l'ordre
            SortStructuredList(myTable()\myColumn(),#PB_Sort_Ascending,OffsetOf(Column\Order),TypeOf(Column\Order))
            ForEach \myColumn()
                If \myColumn()\FilterOn
                    X1=X+2
                    X2=X1+ImgSize
                    If (gMouseY>=Y1 And gMouseY<=Y2) And (gMouseX>=X1 And gMouseX<=X2)
                        SetGadgetAttribute(\IdCanvas,#PB_Canvas_Cursor,#PB_Cursor_Hand)
                        *ColumnFiltersHover=@\myColumn()
                        ProcedureReturn #True
                    EndIf
                EndIf
                X+\myColumn()\Widht
            Next
            ProcedureReturn #False
        EndWith
    EndProcedure
    Procedure  HoverColumn()
        With myTable()
            Protected X1,X2,Y1,Y2,X
            ; Si un titre d'entête on regarde en dessous
            If \HeaderTitle<>""
                Y1=\myProperties\HeaderHeight
            EndIf
            Y2=Y1+\myProperties\ColumnTitleHeight
             ; Trie la liste sur l'ordre
            SortStructuredList(myTable()\myColumn(),#PB_Sort_Ascending,OffsetOf(Column\Order),TypeOf(Column\Order))
            ForEach \myColumn() 
                X1=X
                X2=X1+\myColumn()\Widht
                If (gMouseY>=Y1 And gMouseY<=Y2) And (gMouseX>=X1 And gMouseX<=X2)
                    *ColumnHover=@\myColumn()
                    SetGadgetAttribute(\IdCanvas,#PB_Canvas_Cursor,#PB_Cursor_Hand)
                    ProcedureReturn #True
                EndIf
                X+\myColumn()\Widht
            Next
            ProcedureReturn #False
        EndWith
    EndProcedure
    Procedure MovecolumnToRight()
        With myTable()\myColumn()
            ; pointe sur la colonne
            ChangeCurrentElement(myTable()\myColumn(),*ColumnHover)
            ; Trie la liste sur l'ordre
            SortStructuredList(myTable()\myColumn(),#PB_Sort_Ascending,OffsetOf(Column\Order),TypeOf(Column\Order))
            ; Regarde si une colonne après
            If NextElement(myTable()\myColumn())
                ; Change l'ordre
                \Order-1 
                ; pointe sur la colonne
                ChangeCurrentElement(myTable()\myColumn(),*ColumnHover)
                \Order+1
                Draw()
            EndIf
        EndWith
    EndProcedure
    Procedure MovecolumnToLeft()
        With myTable()\myColumn()
            ; pointe sur la colonne
            ChangeCurrentElement(myTable()\myColumn(),*ColumnHover)
            ; Trie la liste sur l'ordre
            SortStructuredList(myTable()\myColumn(),#PB_Sort_Ascending,OffsetOf(Column\Order),TypeOf(Column\Order))
            ; Regarde si une colonne avant
            If PreviousElement(myTable()\myColumn())
                ; Change l'ordre
                \Order+1 
                ; pointe sur la colonne
                ChangeCurrentElement(myTable()\myColumn(),*ColumnHover)
                \Order-1
                Draw()
            EndIf
        EndWith
    EndProcedure
    Procedure ActiveSortToColumn()
        With myTable()\myColumn()
            ; Désactive le tri pour toute les colonne
            ForEach myTable()\myColumn()
                If @myTable()\myColumn()=*ColumnHover
                    If \LinkedTable="" ; SI pas de liaison
                        myTable()\OrderClause="ORDER BY "+myTable()\TableName+"."+\DbColumnName
                    Else
                        myTable()\OrderClause="ORDER BY "+\LinkedTable+"."+\StrangerColumn
                    EndIf
                    If \OrderAscOn
                        \OrderAscOn=#False
                        \OrderDesOn=#True
                         myTable()\OrderClause+" DESC"
                    ElseIf \OrderDesOn
                        \OrderDesOn=#False
                        \OrderAscOn=#True
                        myTable()\OrderClause+" ASC"
                    ElseIf Not \OrderAscOn And Not \OrderDesOn
                         \OrderDesOn=#False
                         \OrderAscOn=#True
                         myTable()\OrderClause+" ASC"
                    EndIf
                Else
                    \OrderAscOn=#False
                    \OrderDesOn=#False
                EndIf
            Next
            Draw()
        EndWith
    EndProcedure
    Procedure ManageDataScroll()
        Protected req.s,X,Y,Max
        With myTable()
            ; Compte le nombre de record
;             req="SELECT COUNT(*)  FROM "+\TableName
            req=MakeCountRequest()
            If \WhereClause<>""
                req+" WHERE  "+\WhereClause
                If \FiltersClause<>""
                    req+" AND "+\FiltersClause
                EndIf
            EndIf
            If \WhereClause="" And \FiltersClause<>""
                req+" WHERE  "+\FiltersClause
            EndIf
            If DatabaseQuery(\IdDb,req)=0
                MessageRequester("ManageDataScroll Error",DatabaseError())
                ProcedureReturn 
            EndIf
            FirstDatabaseRow(\IdDb)
            \NbRecord=GetDatabaseLong(\IdDb,0)
            FinishDatabaseQuery(\IdDb)
            ; Si plus de record que de lignes affichées
            If \NbRecord>\NumberLine
               Max=(\NbRecord-\NumberLine)+1
                If Not IsGadget(\IdScrollV)
                    ; On reduit la taille du canvas
                    ResizeGadget(\IdCanvas,#PB_Ignore,#PB_Ignore,\Width-\myProperties\LineHeight,#PB_Ignore)
                    ; Si ascenseur horizontal on reduit sa largeur
                    If IsGadget(\IdScrollH)
                        ResizeGadget(\IdScrollH,#PB_Ignore,#PB_Ignore,GadgetWidth(\IdCanvas),#PB_Ignore)
                    EndIf
                    ; Ajoute l'ascensseur
                    X=GadgetX(\IdCanvas)+GadgetWidth(\IdCanvas)
                    Y=GadgetY(\IdCanvas)
                    \IdScrollV=ScrollBarGadget(#PB_Any,X,Y,\myProperties\LineHeight,GadgetHeight(\IdCanvas),0,Max,0,#PB_ScrollBar_Vertical)
                    SetGadgetData(\IdScrollV,Val(MapKey(myTable())))
                    BindGadgetEvent(\IdScrollV,@EventScrollV())
                Else
                    ResizeGadget(\IdScrollV,#PB_Ignore,#PB_Ignore,#PB_Ignore,GadgetHeight(\IdCanvas))
                EndIf
            Else
                If IsGadget(\IdScrollV)
                    ; On augmente la taille du canvas
                    ResizeGadget(\IdCanvas,#PB_Ignore,#PB_Ignore,\Width+\myProperties\LineHeight,#PB_Ignore)
                    ; Si ascenseur horizontal on augmente sa largeur
                    If IsGadget(\IdScrollH)
                        ResizeGadget(\IdScrollH,#PB_Ignore,#PB_Ignore,GadgetWidth(\IdCanvas),#PB_Ignore)
                    EndIf
                    FreeGadget(\IdScrollV)
                EndIf
            EndIf
        EndWith
    EndProcedure
    Procedure MakeRequest()
        With myTable()
            Protected N,Exists.b
            Protected NewList StrangerTable.s()
            \req="SELECT "
             ; Trie la liste sur l'ordre
            SortStructuredList(myTable()\myColumn(),#PB_Sort_Ascending,OffsetOf(Column\Order),TypeOf(Column\Order))
            ; Charge l'ID
            \req+\TableName+"."+\IdTable+","
            ForEach \myColumn() 
                N+1
                ; Si pas colonne mémoire
                If \myColumn()\DbColumnName<>""
                    ; Si pas de liaison avec une table étrangère
                    If \myColumn()\LinkedTable=""
                        \req+\TableName+"."+\myColumn()\DbColumnName
                    Else ; Liaison avec une table étrangère
                         ; Regarde dans la liste des table étrangère si la table existe
                         ; si elle n'existe pas on l'ajoute
                        Exists=#False
                        ForEach StrangerTable()
                            If \myColumn()\LinkedTable=StrangerTable()
                                Exists=#True
                            EndIf
                        Next
                        If Not Exists
                            AddElement(StrangerTable())
                            StrangerTable()=" LEFT OUTER JOIN "+\myColumn()\LinkedTable
                            StrangerTable()+" ON "+\myColumn()\LinkedTable+"."+\myColumn()\StrangerId+"="+\TableName+"."+\myColumn()\DbColumnName+" "
                        EndIf
                        \req+\myColumn()\LinkedTable+"."+\myColumn()\StrangerColumn
                    EndIf
                    \req+","
                EndIf
            Next
            ; Retire la dernière virgule à la requète
            \req=Left(\req,Len(\req)-1)
            \req+" FROM "+\TableName
            ForEach StrangerTable()
                \req+StrangerTable()
            Next
        EndWith
    EndProcedure
    Procedure DrawData()
        Protected req.s,lOf,lTo,N,Y,X,YT,XT,CurrentDataLine,Color,Txt.s
        Protected  CalculFunction.proCalcul
        With myTable()
            req=\req
            ; Ajout des limites de lecture de la table
            ; Si l'acensseur vertical est actif on le prend en compte
            If IsGadget(\IdScrollV)
                lOf=GetGadgetState(\IdScrollV)
                CurrentDataLine=GetGadgetState(\IdScrollV)
            EndIf
            ; Ajout de where clause
            If \WhereClause<>""
                req+" WHERE "+\WhereClause
                If \FiltersClause<>""
                    req+" AND "+\FiltersClause
                EndIf
            EndIf
            If \WhereClause="" And \FiltersClause<>""
                req+" WHERE "+\FiltersClause
            EndIf
            ; Ajout du tri à la table
            req+\OrderClause
            lTo=\NumberLine
            req+" LIMIT "+Str(lOf)+","+Str(lTo)+" "
            If DatabaseQuery(\IdDb,req)=0
                MessageRequester("DrawData Error",DatabaseError(),#PB_MessageRequester_Error)
                ProcedureReturn #False
            EndIf
            ; Efface les ligne en mémoire
            ClearList(myDataLine())
            ; On commence sous le titre de colonne
            Y=\myProperties\ColumnTitleHeight
            While NextDatabaseRow(\IdDb)
                X=0
                AddElement(myDataLine())
                ; Sauvegarde de l'id
                myDataLine()\Id=GetDatabaseLong(\IdDb,0)
                ; Si aucune ligne n'est sélectionnée on sélectionne la première ligne
                If \IdLigneSelected=-1
                    \IdLigneSelected=myDataLine()\Id
                EndIf
                ; Choix de la couleur et la police suivant que la ligne sélectionnée paire ou impaire
                If myDataLine()\Id=\IdLigneSelected ; Si la ligne est sélectionnée
                                                    ; Dessin du cadre de sélection
                    AddPathBox(0,Y,\TotalWidthColumn,\myProperties\LineHeight)
                    VectorSourceColor(\myProperties\SelectLineColors\Bg)
                    FillPath()
                    ; Choix de la police
                    VectorFont(FontID(\myProperties\SelectLineFont))
                    Color=\myProperties\SelectLineColors\Fg
                Else ; La ligne n'est pas sélectionnée
                    If CurrentDataLine & 1 ; Ligne impaire
                        VectorFont(FontID(\myProperties\OddLineFont))
                        Color=\myProperties\OddLineColors\Fg
                    Else ; ligne pair
                        VectorFont(FontID(\myProperties\PairLineFont))
                        Color=\myProperties\PairLineColors\Fg
                    EndIf
                EndIf
                ; Centrage de la ligne horizontalement
                YT=Y+(\myProperties\LineHeight/2)
                YT-(VectorTextHeight("W")/2)
                ; Parcour de toutes les colonnes
                N=0
                ; Trie la liste sur l'ordre
                SortStructuredList(myTable()\myColumn(),#PB_Sort_Ascending,OffsetOf(Column\Order),TypeOf(Column\Order))
                ForEach \myColumn()
                    AddElement(myDataLine()\myColumn())
                    ; Si pas une colonne mémoire
                    If \myColumn()\DbColumnName<>""
                        N+1
                        Select DatabaseColumnType(\IdDb,N)
                            Case #PB_Database_Long
                                myDataLine()\myColumn()\Type=#PB_Database_Long
                                myDataLine()\myColumn()\Value=Str(GetDatabaseLong(\IdDb,N))
                            Case #PB_Database_String
                                myDataLine()\myColumn()\Type=#PB_Database_String
                                myDataLine()\myColumn()\Value=GetDatabaseString(\IdDb,N)
                            Case #PB_Database_Float 
                                myDataLine()\myColumn()\Type=#PB_Database_Float
                                myDataLine()\myColumn()\Value=StrF(GetDatabaseLong(\IdDb,N))
                            Case #PB_Database_Double
                                myDataLine()\myColumn()\Type=#PB_Database_Double
                                myDataLine()\myColumn()\Value=StrD(GetDatabaseLong(\IdDb,N))
                            Case #PB_Database_Quad  
                                myDataLine()\myColumn()\Type=#PB_Database_Quad
                                myDataLine()\myColumn()\Value=StrD(GetDatabaseLong(\IdDb,N))
                            Case #PB_Database_Blob  
                                MessageRequester("DrawData Error","The blob type is not available with this module",#PB_MessageRequester_Error)
                                ProcedureReturn #False
                        EndSelect
                    Else ; Si une colonne mémoire
                         myDataLine()\myColumn()\Type=-1 ; Colonne mémoire
                        If \myColumn()\CalculateCallback>-1
                            CalculFunction=\myColumn()\CalculateCallback
                             myDataLine()\myColumn()\Value=CalculFunction(GetDatabaseLong(\IdDb,0))
                        EndIf             
                    EndIf
                    ; Contatene le texte si nécessaire
                    Txt=myDataLine()\myColumn()\Value
                    While  VectorTextWidth(Txt)>(\myColumn()\Widht-(\myColumn()\Margin*2))
                        Txt=Left(Txt,Len(Txt)-4)
                        Txt+"..."
                    Wend    
                    ; Mise en place du texte dans la colonne
                    Select \myColumn()\Alignment
                        Case #Left
                            XT=X+\myColumn()\Margin
                        Case #Right
                            XT=X+(\myColumn()\Widht-(VectorTextWidth(Txt)+\myColumn()\Margin))
                        Case #Center
                            XT=X+(\myColumn()\Widht/2)
                            XT-VectorTextWidth(Txt)/2
                    EndSelect
                    ; Dessin du texte
                    VectorSourceColor(Color)
                    MovePathCursor(XT,YT)
                    DrawVectorText(Txt)
                    X+\myColumn()\Widht
                Next
                Y+\myProperties\LineHeight
                CurrentDataLine+1
            Wend
        EndWith
    EndProcedure
    Procedure EventScrollV()
        FindMapElement(myTable(),Str(GetGadgetData(EventGadget())))
        Draw()
    EndProcedure
    Procedure HoverLigne(NotSelected.b=#True)
        Protected Y1,Y2,X1=4,X2,H
        With myTable()
            X2=GadgetWidth(\IdCanvas)-4
            H=\myProperties\LineHeight
            If \HeaderTitle<>""
                Y1=\myProperties\HeaderHeight
            EndIf
            Y1+\myProperties\ColumnTitleHeight
        EndWith
        If (gMouseX>=X1 And gMouseX<=X2)
            ForEach myDataLine()
                With myDataLine()
                    Y2=Y1+H
                    If (gMouseY>=Y1 And gMouseY<=Y2) 
                        If \Id<>myTable()\IdLigneSelected Or NotSelected=#False
                            SetGadgetAttribute(myTable()\IdCanvas,#PB_Canvas_Cursor,#PB_Cursor_Hand)
                            *LigneHover=@myDataLine()
                            ProcedureReturn #True
                        EndIf
                    EndIf
                EndWith
                Y1+H
            Next
        EndIf
        ProcedureReturn #False
    EndProcedure
    Procedure ActiveShearch()
        Protected X,Y,H,W,TW
        ; La hauteur du champ de recherche est égale à la hauteur du titre de colonne
        With myTable()
            H=\myProperties\ColumnTitleHeight
            ; X on démare à la position du canvas
            X=WindowX(\myWindow,#PB_Window_InnerCoordinate)+GadgetX(\IdCanvas)+4
            ; Y on démare au canvas
            Y=WindowY(\myWindow,#PB_Window_InnerCoordinate)+GadgetY(\IdCanvas)+4
            ; Si une titre d'entête on démare en dessous
            If \HeaderTitle<>""
                Y+\myProperties\HeaderHeight
            EndIf
        EndWith
        ForEach myTable()\myColumn()
            With myTable()\myColumn()
                ; La largeur du champ de recherche est égale à la largeur de colonne
                W=\Widht
                If @myTable()\myColumn() = *ColumnShearchHover
                    If   myTable()\ShearchWindow=-1
                        ;                     CloseWindow(myTable()\ShearchWindow)
                    EndIf
                    myTable()\ShearchWindow=OpenWindow(#PB_Any,X,Y,W,H,"",#PB_Window_BorderLess|#PB_Window_Invisible,WindowID(myTable()\myWindow))
                    myTable()\ShearchField=StringGadget(#PB_Any,0,0,WindowWidth(myTable()\ShearchWindow),WindowHeight(myTable()\ShearchWindow),\ShearchValue)
                    ; Rend visible la fenêtre
                    HideWindow(myTable()\ShearchWindow,#False)
                    SetActiveWindow(myTable()\ShearchWindow)
                    SetActiveGadget(myTable()\ShearchField)
                    SetGadgetData(myTable()\ShearchField,*ColumnShearchHover)
                    ; Ajout de raccourcis clavier pour désactiver le stringgadget
                    AddKeyboardShortcut(myTable()\ShearchWindow,#PB_Shortcut_Tab,$00)
                    AddKeyboardShortcut(myTable()\ShearchWindow,#PB_Shortcut_Return,$00)
                    AddKeyboardShortcut(myTable()\ShearchWindow,#PB_Shortcut_Escape,$01)
                    ; Ajout des callback pour désactiver le stringgadget
                    BindEvent(#PB_Event_Menu,@DisableShearchField(),myTable()\ShearchWindow,$00)
                    BindEvent(#PB_Event_Menu,@ErazeShearch(),myTable()\ShearchWindow,$01)
                    BindGadgetEvent(myTable()\ShearchField,@SetShearhClause())
                    Break
                EndIf
                X+\Widht
            EndWith
        Next
    EndProcedure
    Procedure DisableShearchField()
        With myTable()
            ; ferme la fenêtre de recherche
            CloseWindow(\ShearchWindow)
            \ShearchWindow=-1
        EndWith
    EndProcedure
    Procedure SetShearhClause()
        With myTable()
            ; Efface en premier toutes les autre recherches
            ForEach \myColumn()
                \myColumn()\ShearchValue=""
            Next
            ChangeCurrentElement(\myColumn(),GetGadgetData(\ShearchField))
            \myColumn()\ShearchValue=GetGadgetText(\ShearchField)
            \WhereClause=\TableName+"."+\myColumn()\DbColumnName+" LIKE '"+GetGadgetText(\ShearchField)+"%' "
            Draw()
;             DisableGadget(\IdCanvas,#True)
            SetActiveGadget(\ShearchField)
        EndWith
    EndProcedure
    Procedure ErazeShearch()
        With myTable()
            ChangeCurrentElement(\myColumn(),GetGadgetData(\ShearchField))
            \myColumn()\ShearchValue=""
            \WhereClause=""
            Draw()
            DisableShearchField()
        EndWith
    EndProcedure
    Procedure ActiveFilters()
                Protected X,Y,H,W,TW
        ; La hauteur du champ de recherche est égale à la hauteur du titre de colonne
        With myTable()
            H=\myProperties\ColumnTitleHeight
            ; X on démare à la position du canvas
            X=WindowX(\myWindow,#PB_Window_InnerCoordinate)+GadgetX(\IdCanvas)+4
            ; Y on démare au canvas
            Y=WindowY(\myWindow,#PB_Window_InnerCoordinate)+GadgetY(\IdCanvas)+4
            ; Si une titre d'entête on démare en dessous
            If \HeaderTitle<>""
                Y+\myProperties\HeaderHeight
            EndIf
        EndWith
        ForEach myTable()\myColumn()
            With myTable()\myColumn()
                ; La largeur du champ de recherche est égale à la largeur de colonne
                W=\Widht
                If @myTable()\myColumn() = *ColumnFiltersHover
                    myTable()\ShearchWindow=OpenWindow(#PB_Any,X,Y,W,H,"",#PB_Window_BorderLess|#PB_Window_Invisible,WindowID(myTable()\myWindow))
                    myTable()\FiltersCombo=ComboBoxGadget(#PB_Any,0,0,WindowWidth(myTable()\ShearchWindow),WindowHeight(myTable()\ShearchWindow))
                    ; Remplisage du combo
                    FillFiltersCombo()
                    ; Rend visible la fenêtre
                    HideWindow(myTable()\ShearchWindow,#False)
                    SetActiveWindow(myTable()\ShearchWindow)
                    SetActiveGadget(myTable()\FiltersCombo)
                    SetGadgetData(myTable()\FiltersCombo,*ColumnShearchHover)
                    ; Ajout de raccourcis clavier pour désactiver le stringgadget
                    AddKeyboardShortcut(myTable()\ShearchWindow,#PB_Shortcut_Tab,$00)
                    AddKeyboardShortcut(myTable()\ShearchWindow,#PB_Shortcut_Return,$00)
                    AddKeyboardShortcut(myTable()\ShearchWindow,#PB_Shortcut_Escape,$01)
                    ; Ajout des callback pour désactiver le stringgadget
                    BindEvent(#PB_Event_Menu,@DisableShearchField(),myTable()\ShearchWindow,$00)
                    BindEvent(#PB_Event_Menu,@ErazeFilter(),myTable()\ShearchWindow,$01)
                    BindGadgetEvent(myTable()\FiltersCombo,@SetFiltersClause())
                    Break
                EndIf
                X+\Widht
            EndWith
        Next
    EndProcedure
    Procedure FillFiltersCombo()
        With myTable()
            Protected req.s,N,LgnSeleted
            req="SELECT "+\myColumn()\StrangerId+","+\myColumn()\StrangerColumn+" FROM "+\myColumn()\LinkedTable+" ORDER BY "+\myColumn()\StrangerColumn
            ClearGadgetItems(\FiltersCombo)
            If DatabaseQuery(\IdDb,req)=0
                MessageRequester("FillFiltersCombo Error",DatabaseError(),#PB_MessageRequester_Error)
                ProcedureReturn #False
            EndIf
            AddGadgetItem(\FiltersCombo,-1,\myProperties\FiltersDisableMesage)
            SetGadgetItemData(\FiltersCombo,N,-1)
            N+1
            While NextDatabaseRow(\IdDb)
                AddGadgetItem(\FiltersCombo,-1,GetDatabaseString(\IdDb,1))
                SetGadgetItemData(\FiltersCombo,N,GetDatabaseLong(\IdDb,0))
                If GetDatabaseLong(\IdDb,0)=\myColumn()\FiltersId
                    LgnSeleted=N
                EndIf
                N+1
            Wend
            FinishDatabaseQuery(\IdDb)
            SetGadgetState(\FiltersCombo,LgnSeleted)
        EndWith
    EndProcedure
    Procedure SetFiltersClause()
        Protected Id
        With myTable()
            Id=GetGadgetItemData(\FiltersCombo,GetGadgetState(\FiltersCombo))
            ; pointe sur la colonne concernée
            ChangeCurrentElement(\myColumn(),*ColumnFiltersHover)
            \myColumn()\FiltersId=Id
            If Id>-1
                \FiltersClause=\myColumn()\LinkedTable+"."+\myColumn()\StrangerId+"="+ID+" "
            Else
                \FiltersClause=""
            EndIf
            DisableShearchField()
            Draw()
        EndWith
    EndProcedure
    Procedure ErazeFilter()
        With myTable()
            ChangeCurrentElement(\myColumn(),*ColumnFiltersHover)
            \myColumn()\FiltersId=-1
            \FiltersClause=""
            DisableShearchField()
            Draw()
        EndWith
    EndProcedure
    Procedure.s MakeCountRequest()
        With myTable()
            Protected N,Exists.b,req.s
            Protected NewList StrangerTable.s()
            req="SELECT COUNT(*) "
            ; Trie la liste sur l'ordre
            SortStructuredList(myTable()\myColumn(),#PB_Sort_Ascending,OffsetOf(Column\Order),TypeOf(Column\Order))
            ; Charge l'ID
;             req+\TableName+"."+\IdTable+","
            ForEach \myColumn() 
                N+1
                ; Si pas colonne mémoire
                If \myColumn()\DbColumnName<>""
                    ; Si pas de liaison avec une table étrangère
                    If \myColumn()\LinkedTable=""
;                         \req+\TableName+"."+\myColumn()\DbColumnName
                    Else ; Liaison avec une table étrangère
                         ; Regarde dans la liste des table étrangère si la table existe
                         ; si elle n'existe pas on l'ajoute
                        Exists=#False
                        ForEach StrangerTable()
                            If \myColumn()\LinkedTable=StrangerTable()
                                Exists=#True
                            EndIf
                        Next
                        If Not Exists
                            AddElement(StrangerTable())
                            StrangerTable()=" LEFT OUTER JOIN "+\myColumn()\LinkedTable
                            StrangerTable()+" ON "+\myColumn()\LinkedTable+"."+\myColumn()\StrangerId+"="+\TableName+"."+\myColumn()\DbColumnName+" "
                        EndIf
;                         req+\myColumn()\LinkedTable+"."+\myColumn()\StrangerColumn
                    EndIf
;                     req+","
                EndIf
            Next
            ; Retire la dernière virgule à la requète
;             \req=Left(\req,Len(\req)-1)
            req+" FROM "+\TableName
            ForEach StrangerTable()
                req+StrangerTable()
            Next
            ProcedureReturn req
        EndWith
    EndProcedure
    ;}
    ;-* PUBLIC PROCEDURE
    Procedure Create(Id,X,Y,Width,NumberLine,IdDb.i,TableName.s,IdTable.s,Title.s="")
        ; si Id=Pb_Any recherche la première place libre dans la map
        If Id=#PB_Any
            Id=0
            While FindMapElement(myTable(),Str(Id))>0
                Id+1
            Wend
        EndIf
        ; Vérifie que la map n'existe pas
        If FindMapElement(myTable(),Str(Id))>0
            MessageRequester("Error Create","This Id "+Str(Id)+" already exists")
            ProcedureReturn -1
        EndIf
        ; Ajoute la map
        AddMapElement(myTable(),Str(Id))
        ; Remplis les propriétés de la table par défaut
        CreateProperties()
        ; Remplis les champs de la map
        With myTable()
            \IdDb=IdDb
            \NumberLine=NumberLine
            \Width=Width
            \HeaderTitle=Title
            \TableName=TableName
            \IdTable=IdTable
            \X=X
            \Y=Y
            ; Au départ aucune ligne n'est sélectionnée
            \IdLigneSelected=-1
            ; Calcul de la hauteur de la table
            CalculTableHeight()  
            ; Par défaut par de OrderClause
            \OrderClause=""
            ; Par défaut pas de callback à la sélection
            \SelectCallback=-1
            ; Par défaut pas de callback au double click
            \DoubleClickCallback=-1
            \ShearchWindow=-1
            ProcedureReturn Val(MapKey(myTable()))
        EndWith
    EndProcedure
    Procedure GetTableHeight()
        With myTable()
            ProcedureReturn \Height
        EndWith
    EndProcedure
    Procedure UseTable(IdTable)
        ; pointe sur la un table
        If FindMapElement(myTable(),Str(IdTable))=0
            MessageRequester("UseTable","This Id "+Str(IdTable)+" do Not exits",#PB_MessageRequester_Error)
            ProcedureReturn #False
        EndIf
        ProcedureReturn #True
    EndProcedure
    Procedure AddColumn(Label.s,Width,DbColumnName.s="")
        ; Ajoute une colonne à la table
        ; Si DbColumnName est vide la colonne sera de type mémoire
        With myTable()\myColumn()
            AddElement(myTable()\myColumn())
            \DbColumnName=DbColumnName
            \Label=Label
            \Widht=Width
            ; L'ordre dans lequel les colonnes seront affichées, cette ordre pourrat être modifié
            ; par l'utilisateur
            \Order=ListSize(myTable()\myColumn())
            ; Les flags pour différentes actions sur les colonnes
            \FilterOn=#False
            \OrderOn=#True
            \ShearchOn=#False
            \MoveableOn=#True
            \ResizeOn=#True
            ; Les flag de tri (par défaut inactif)
            \OrderAscOn=#False
            \OrderDesOn=#False
            ; Par défaut pas de callback
            \ResizeCallback=-1
             ; Par défaut pas de table liée
            \StrangerColumn=""
            \LinkedTable=""
            ; Alignement et marge
            \Alignment=#Left
            \Margin=6
            ; Ahgmente la taille total des colonnes
            myTable()\TotalWidthColumn + Width
            ; par défaut pas de callback de calcul
            \CalculateCallback=-1
            ; Retourne l'index de la liste
            ; par défaut pas de filtre si colonne liée
            \FiltersId=-1
            ProcedureReturn ListIndex(myTable()\myColumn())
        EndWith
    EndProcedure
    Procedure UseColumn(IdColumn)
        With myTable()\myColumn()
            If SelectElement(myTable()\myColumn(),IdColumn)=0
                MessageRequester("UseColumn","This Id "+Str(IdColumn)+" do Not exits",#PB_MessageRequester_Error)
                ProcedureReturn #False
            EndIf
            ProcedureReturn #True
        EndWith
    EndProcedure
    Procedure Draw()
        With myTable()
            ; Création du canvas s'il n'existe pas encore
            If IsGadget(\IdCanvas)=0
                ; Mémorise la fenêtre concernée
                \myWindow=GetActiveWindow()
                \IdCanvas=CanvasGadget(#PB_Any,\X,\Y,\Width,\Height,#PB_Canvas_Keyboard)
                ; Mémorise l'id dans le canvas pour Event
                SetGadgetData(\IdCanvas,Val(MapKey(myTable())))
                ; Mise en place du callback
                BindGadgetEvent(\IdCanvas,@Event())
            EndIf
            UseGadgetList(WindowID(\myWindow))
            ; Génération de la requete
            MakeRequest()
            ; Regarde si les ascenseurs sont nécessaire
            ManageScrollbar()
            ; Dessin de l'image temporaire
            DrawTempImage()
            ; Dessine le canvas
            DrawCanvas()
        EndWith
    EndProcedure
    Procedure EnableColumnSearch(State.b=#True)
        With myTable()\myColumn()
            If \DbColumnName=""
                MessageRequester("EnableColumnSearch Error","You can't enable the shearch function for a memoris column",#PB_MessageRequester_Error)
                ProcedureReturn 
            EndIf
            If \LinkedTable<>""
                 MessageRequester("EnableColumnSearch Error","You can't enable the shearch function for a linked column",#PB_MessageRequester_Error)
                ProcedureReturn 
            EndIf
            \ShearchOn=State
        EndWith
    EndProcedure
    Procedure EnableOrderAsc()
        With myTable()\myColumn()
            ; Pas pour les colonnes mémoire
            If \DbColumnName=""
                MessageRequester("EnableOrderAsc Error","You can't ordered a memoris column",#PB_MessageRequester_Error)
                ProcedureReturn 
            EndIf
            PushListPosition(myTable()\myColumn())
            ForEach myTable()\myColumn()
                \OrderAscOn=#False
                \OrderDesOn=#False
            Next
            PopListPosition(myTable()\myColumn())
            \OrderAscOn=#True
            If \LinkedTable="" ; SI pas de liaison
                myTable()\OrderClause="ORDER BY "+myTable()\TableName+"."+\DbColumnName+" ASC"
            Else
                myTable()\OrderClause="ORDER BY "+\LinkedTable+"."+\StrangerColumn+" ASC"
            EndIf
        EndWith
    EndProcedure
    Procedure EnableOrderDes()
        With myTable()\myColumn()
            ; Pas pour les colonnes mémoire
            If \DbColumnName=""
                MessageRequester("EnableOrderDes Error","You can't ordered a memoris column",#PB_MessageRequester_Error)
                ProcedureReturn 
            EndIf
            PushListPosition(myTable()\myColumn())
            ForEach myTable()\myColumn()
                \OrderAscOn=#False
                \OrderDesOn=#False
            Next
            PopListPosition(myTable()\myColumn())
            \OrderDesOn=#True
             If \LinkedTable="" ; SI pas de liaison
                myTable()\OrderClause="ORDER BY "+myTable()\TableName+"."+\DbColumnName+" DESC"
            Else
                myTable()\OrderClause="ORDER BY "+\LinkedTable+"."+\StrangerColumn+" DESC"
            EndIf
        EndWith
    EndProcedure
    Procedure SetColumnResizeCallback(*Callback)
        With myTable()\myColumn()
            \ResizeCallback=*Callback
        EndWith
    EndProcedure
    Procedure SetLink(LinkedTable.s,StrangerId.s,StrangerColumn.s)
        With myTable()\myColumn()
            \ShearchOn=#False
            \LinkedTable=LinkedTable
            \StrangerColumn=StrangerColumn
            \StrangerId=StrangerId
        EndWith
    EndProcedure
    Procedure EnableFilters(State.b=#True)
        With myTable()\myColumn()
            If \LinkedTable=""
                MessageRequester("EnableFilters Error","You can only enable a filter for an linked column")
                ProcedureReturn #False
            EndIf
            \FilterOn=State
            ProcedureReturn #True
        EndWith
    EndProcedure
    Procedure SetCallbackToSelect(*Callback)
        With myTable()
            \SelectCallback=*Callback
        EndWith
    EndProcedure
    Procedure SetDoubleClickCallback(*Callback)
        With myTable()
            \DoubleClickCallback=*Callback
        EndWith
    EndProcedure
    Procedure SetColumnAlignment(Alignment.i)
        With myTable()\myColumn()
            If Alignment<#Left Or Alignment>#Center
                MessageRequester("SetColumnAlignment Error","This aligment type "+Str(Alignment)+" is not available",#PB_MessageRequester_Error)
                ProcedureReturn 
            EndIf
            \Alignment=Alignment
        EndWith
    EndProcedure
    Procedure SetCalculteCallback(*Callback)
        With myTable()\myColumn()
            If \DbColumnName<>""
                MessageRequester("SetCalculteCallback Error","You can't add an calculate callback only for memoris column",#PB_MessageRequester_Error)
                ProcedureReturn 
            EndIf
            \CalculateCallback=*Callback
        EndWith
    EndProcedure
    Procedure SetOrderClause(OrderClause.s)
        With myTable()
            \OrderClause=OrderClause
        EndWith
    EndProcedure
    Procedure Free(IdTable)
        If FindMapElement(myTable(),Str(IdTable))=0
            MessageRequester("Free Error","This table "+Str(IdTable)+" do Not exists ",#PB_MessageRequester_Error)
            ProcedureReturn #False
        EndIf
        ProcedureReturn #True
    EndProcedure
    ;}
    DataSection
        DownArrow:
        IncludeBinary "img\DownArrow.png"
        UpArrow:
        IncludeBinary "img\UpArrow.png"
        Filter:
        IncludeBinary "img\Filter.png"
        shearch:
        IncludeBinary "img\search.png"
        shearchOn:
        IncludeBinary "img\shearchOn.png"
        FilterOn:
        IncludeBinary "img\FilterOn.png"
    EndDataSection
EndModule
; IDE Options = PureBasic 5.50 (Windows - x64)
; CursorPosition = 7
; FirstLine = 21
; Folding = NACwHAAAAAAAAgAAAAAAAAAAAAAMADAAw-
; Markers = 873
; EnableXP