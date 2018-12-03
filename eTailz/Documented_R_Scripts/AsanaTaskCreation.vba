Sub PullAsanaTask()

Dim TaskArr() As String
Dim FlagArr() As String
Dim FeaturesColArr(4) As Integer

Workbooks.Open "P:\Biz Dev\Marketplace Expansion\Asana Tasks\Asana_Task_Master.xlsx"

masterFile = ActiveWorkbook.Name

AsanaTaskIdColumn = Workbooks(masterFile).Sheets(1).Cells.Find("AsanaTaskID").Column

maxAsanaTaskIdRow = Workbooks(masterFile).Sheets(1).Cells(Rows.Count, AsanaTaskIdColumn).End(xlUp).Row

maxAsanaTaskId = Workbooks(masterFile).Sheets(1).Cells(maxAsanaTaskIdRow, AsanaTaskIdColumn)

If Not Cells(2, AsanaTaskIdColumn + 1) = "" Then
    i = 3
    foundEnd = False
    Do While i < maxAsanaTaskIdRow And foundEnd = False
        If Cells(i, AsanaTaskIdColumn + 1) = "" Then
            firstEmptyTask = i
            foundEnd = True
        End If
        i = i + 1
    Loop
Else
    firstEmptyTask = 2
End If

ReDim Preserve TaskArr(0)
TaskArr(0) = Workbooks(masterFile).Sheets(1).Cells(firstEmptyTask + 1, AsanaTaskIdColumn).Value
AsanaTaskDropdownForm.TaskSelectionDD.AddItem TaskArr(UBound(TaskArr))

For i = firstEmptyTask + 1 To maxAsanaTaskIdRow
    If Not Workbooks(masterFile).Sheets(1).Cells(i, AsanaTaskIdColumn).Value = TaskArr(UBound(TaskArr)) Then
        If Workbooks(masterFile).Sheets(1).Cells(i, AsanaTaskIdColumn + 1).Value = "" Then
            If Not Workbooks(masterFile).Sheets(1).Cells(i, AsanaTaskIdColumn).Value = "" Then
                ReDim Preserve TaskArr(UBound(TaskArr) + 1)
                TaskArr(UBound(TaskArr)) = Workbooks(masterFile).Sheets(1).Cells(i, AsanaTaskIdColumn).Value
                AsanaTaskDropdownForm.TaskSelectionDD.AddItem TaskArr(UBound(TaskArr))
            End If
        End If
    End If
Next i

AsanaTaskDropdownForm.Show

AsanaTaskId = AsanaTaskDropdownForm.TaskSelectionDD.SelText

Unload AsanaTaskDropdownForm

AsanaTaskId = CInt(AsanaTaskId)

AsanaTaskRangeStart = Workbooks(masterFile).Sheets(1).Columns(AsanaTaskIdColumn).Find(AsanaTaskId, LookAt:=xlWhole).Row
AsanaTaskRangeEnd = Workbooks(masterFile).Sheets(1).Columns(AsanaTaskIdColumn).Find(AsanaTaskId, searchdirection:=xlPrevious, LookAt:=xlWhole).Row

Workbooks(masterFile).Sheets(1).Range(Cells(AsanaTaskRangeStart, AsanaTaskIdColumn + 1), Cells(AsanaTaskRangeEnd, AsanaTaskIdColumn + 1)).Value = Application.UserName 'Take out for testing
Workbooks(masterFile).Sheets(1).Range(Cells(AsanaTaskRangeStart, 1), Cells(AsanaTaskRangeEnd, AsanaTaskIdColumn - 1)).Copy
ThisWorkbook.Activate
ThisWorkbook.Sheets(1).Range(Cells(2, 1), Cells(AsanaTaskRangeEnd - AsanaTaskRangeStart + 1, AsanaTaskIdColumn - 1)).Select
ThisWorkbook.Sheets(1).Range(Cells(2, 1), Cells(AsanaTaskRangeEnd - AsanaTaskRangeStart + 1, AsanaTaskIdColumn - 1)).PasteSpecial

Workbooks(masterFile).Activate
Workbooks(masterFile).Sheets(1).Range(Cells(AsanaTaskRangeStart, AsanaTaskIdColumn + 2), Cells(AsanaTaskRangeEnd, AsanaTaskIdColumn + 4)).Copy
ThisWorkbook.Activate
ThisWorkbook.Sheets(1).Range(Cells(2, AsanaTaskIdColumn), Cells(AsanaTaskRangeEnd - AsanaTaskRangeStart + 1, AsanaTaskIdColumn + 3)).PasteSpecial



ThisWorkbook.Sheets(1).Cells.NumberFormat = "0"
ThisWorkbook.Sheets(1).Cells.Replace What:="#N/A", Replacement:="", LookAt:=xlWhole, MatchCase:=True

PictureUrlsColumn = ThisWorkbook.Sheets(1).Rows(1).Find("Picture URLs").Column

ThisWorkbook.Sheets(1).Range(Cells(2, PictureUrlsColumn), Cells(AsanaTaskRangeEnd - AsanaTaskRangeStart + 1, PictureUrlsColumn)).FormulaR1C1 = "=IF(IF(RC[2] = """", """", " & _
        "RC[1]&""""&RC[2]&"","")&IF(RC[4] = """", """", RC[3]&""""&RC[4]&"","")&IF(RC[6] = """", """", RC[5]&""""&RC[6]&"","")&IF(RC[8] = """", """", RC[7]&""""&RC[8]&"","")&IF(RC[10]" & _
        "= """", """", RC[11]&""""&RC[10]&"","") <> """", LEFT(IF(RC[2] = """", """", RC[1]&""""&RC[2]&"","")&IF(RC[4] = """", """", RC[3]&""""&RC[4]&"","")&IF(RC[6] = """", " & _
        """"", RC[5]&""""&RC[6]&"","")&IF(RC[8] = """", """", RC[7]&""""&RC[8]&"","")&IF(RC[10] = """", """", RC[11]&""""&RC[10]&"",""), LEN(IF(RC[2] = """", """", RC[1]&""""&" & _
        "RC[2]&"","")&IF(RC[4] = """", """", RC[3]&""""&RC[4]&"","")&IF(RC[6] = """", """", RC[5]&""""&RC[6]&"","")&IF(RC[8] = """", """", RC[7]&""""&RC[8]&"","")&IF(RC[10] = """", " & _
        """"", RC[11]&""""&RC[10]&"",""))-1), """")"

With ThisWorkbook.Sheets(1).Range(Cells(2, PictureUrlsColumn), Cells(AsanaTaskRangeEnd - AsanaTaskRangeStart + 1, PictureUrlsColumn))
    .HorizontalAlignment = xlGeneral
    .VerticalAlignment = xlBottom
    .WrapText = True
    .Orientation = 0
    .AddIndent = False
    .IndentLevel = 0
    .ShrinkToFit = False
    .ReadingOrder = xlContext
    .MergeCells = False
End With

titleFlagColumn = ThisWorkbook.Sheets(1).Rows(1).Find("Title_Flag").Column
AuctionTitleColumn = ThisWorkbook.Sheets(1).Rows(1).Find("Auction Title").Column
DescriptionTitleColumn = ThisWorkbook.Sheets(1).Rows(1).Find("Description").Column

'Fill Features Column Number Arr
For i = 2 To 6
    FeaturesColArr(i - 2) = ThisWorkbook.Sheets(1).Rows(1).Find("Attribute" & i & "_Value").Column
Next i

ReDim Preserve FlagArr(0)

For i = 2 To AsanaTaskRangeEnd - AsanaTaskRangeStart + 1

    'Title Check
    If Not Cells(i, titleFlagColumn).Value = "" Then
        If InStr(Cells(i, titleFlagColumn).Value, ", ") = 0 Then
            substring = LCase(Cells(i, titleFlagColumn).Value)
            'Find freq of substring
            Z = 1
            TextPos = 0
            Do While Z <= UBound(Split(LCase(Cells(i, AuctionTitleColumn).Value), substring))
                LenFlag = Len(substring)
                TextStart = InStr(LCase(Right(Cells(i, AuctionTitleColumn).Value, Len(Cells(i, AuctionTitleColumn).Value) - TextPos)), LCase(substring))
                Cells(i, AuctionTitleColumn).Characters(TextStart + TextPos, LenFlag).Font.Color = vbRed
                TextPos = LenFlag + TextStart - 1
                Z = Z + 1
            Loop
        Else
            'Create array of objects separated by ", "
            ReDim Preserve FlagArr(UBound(Split(Cells(i, titleFlagColumn).Value, ", ")))
            FlagArr() = Split(LCase(Cells(i, titleFlagColumn).Value), ", ")
            'Highlight all text for each value
            For y = 0 To UBound(FlagArr)
                Z = 1
                TextPos = 0
                Do While Z <= UBound(Split(LCase(Cells(i, AuctionTitleColumn).Value), FlagArr(y)))
                    LenFlag = Len(FlagArr(y))
                    TextStart = InStr(LCase(Right(Cells(i, AuctionTitleColumn).Value, Len(Cells(i, AuctionTitleColumn).Value) - TextPos)), LCase(FlagArr(y)))
                    Cells(i, AuctionTitleColumn).Characters(TextStart + TextPos, LenFlag).Font.Color = vbRed
                    TextPos = LenFlag + TextStart - 1
                    Z = Z + 1
                Loop
            Next y
        End If
    End If

    'Description Check
    If Not Cells(i, titleFlagColumn + 1).Value = "" Then
        If InStr(Cells(i, titleFlagColumn + 1).Value, ", ") = 0 Then
            substring = LCase(Cells(i, titleFlagColumn + 1).Value)
            'Find freq of substring
            Z = 1
            TextPos = 0
            Do While Z <= UBound(Split(LCase(Cells(i, DescriptionTitleColumn).Value), substring))
                LenFlag = Len(substring)
                TextStart = InStr(LCase(Right(Cells(i, DescriptionTitleColumn).Value, Len(Cells(i, DescriptionTitleColumn).Value) - TextPos)), LCase(substring))
                Cells(i, DescriptionTitleColumn).Characters(TextStart + TextPos, LenFlag).Font.Color = vbRed
                TextPos = LenFlag + TextStart - 1
                Z = Z + 1
            Loop
        Else
            'Create array of objects separated by ", "
            ReDim Preserve FlagArr(UBound(Split(Cells(i, titleFlagColumn + 1).Value, ", ")))
            FlagArr() = Split(LCase(Cells(i, titleFlagColumn + 1).Value), ", ")
            'Highlight all text for each value
            For y = 0 To UBound(FlagArr)
                Z = 1
                TextPos = 0
                Do While Z <= UBound(Split(LCase(Cells(i, DescriptionTitleColumn).Value), FlagArr(y)))
                    LenFlag = Len(FlagArr(y))
                    TextStart = InStr(LCase(Right(Cells(i, DescriptionTitleColumn).Value, Len(Cells(i, DescriptionTitleColumn).Value) - TextPos)), LCase(FlagArr(y)))
                    Cells(i, DescriptionTitleColumn).Characters(TextStart + TextPos, LenFlag).Font.Color = vbRed
                    TextPos = LenFlag + TextStart - 1
                    Z = Z + 1
                Loop
            Next y
        End If
    End If

    'Features Check
    For x = LBound(FeaturesColArr) To UBound(FeaturesColArr)
        If Not Cells(i, titleFlagColumn + 2).Value = "" Then
            If InStr(Cells(i, titleFlagColumn + 2).Value, ", ") = 0 Then
                substring = LCase(Cells(i, titleFlagColumn + 2).Value)
                'Find freq of substring
                Z = 1
                TextPos = 0
                Do While Z <= UBound(Split(LCase(Cells(i, FeaturesColArr(x)).Value), substring))
                    LenFlag = Len(substring)
                    TextStart = InStr(LCase(Right(Cells(i, FeaturesColArr(x)).Value, Len(Cells(i, FeaturesColArr(x)).Value) - TextPos)), LCase(substring))
                    Cells(i, FeaturesColArr(x)).Characters(TextStart + TextPos, LenFlag).Font.Color = vbRed
                    TextPos = LenFlag + TextStart - 1
                    Z = Z + 1
                Loop
            Else
                'Create array of objects separated by ", "
                ReDim Preserve FlagArr(UBound(Split(Cells(i, titleFlagColumn + 2).Value, ", ")))
                FlagArr() = Split(LCase(Cells(i, titleFlagColumn + 2).Value), ", ")
                'Highlight all text for each value
                For y = 0 To UBound(FlagArr)
                    Z = 1
                    TextPos = 0
                    Do While Z <= UBound(Split(LCase(Cells(i, FeaturesColArr(x)).Value), FlagArr(y)))
                        LenFlag = Len(FlagArr(y))
                        TextStart = InStr(LCase(Right(Cells(i, FeaturesColArr(x)).Value, Len(Cells(i, FeaturesColArr(x)).Value) - TextPos)), LCase(FlagArr(y)))
                        Cells(i, FeaturesColArr(x)).Characters(TextStart + TextPos, LenFlag).Font.Color = vbRed
                        TextPos = LenFlag + TextStart - 1
                        Z = Z + 1
                    Loop
                Next y
            End If
        End If
    Next x
Next i

Cells(1, 1).Select

Application.DisplayAlerts = False
Workbooks(masterFile).Save
Workbooks(masterFile).Close masterFile
Application.DisplayAlerts = True

End Sub
