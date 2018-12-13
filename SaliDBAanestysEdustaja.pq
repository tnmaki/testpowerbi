let
    GetData = (pkStartValue as number) => 
        let
            SaliDBAanestysEdustaja = 
                Json.Document(
                    Web.Contents(
                        "http://avoindata.eduskunta.fi/api/v1/tables/SaliDBAanestysEdustaja/batch?pkStartValue=7277380&pkName=EdustajaId", [Query=[pkStartValue=Number.ToText(pkStartValue)]])
                    ), // edell‰ Chris Webbin temput Web.Contents query optionsin avulla!!
            ResultAll = if SaliDBAanestysEdustaja[rowCount] > 0 
                            then Table.Combine(List.Transform(SaliDBAanestysEdustaja[rowData], each Table.FromRows({_}, SaliDBAanestysEdustaja [columnNames]))) // JSONista listaksi
                            else null, // jos rowCount 0, niin palautetaan null
            #"Filtered Rows" = Table.SelectRows(ResultAll, each Number.Mod(Number.FromText([AanestysId]),2) = 1), // Vain parittomat AanestysId:t eli suomenkieliset
            pkLastValue = SaliDBAanestysEdustaja[pkLastValue]
        in
            #"Filtered Rows",
    
    Output = List.Generate( ()=>
        [Result = try GetData(7277380) otherwise null, pkStartValue = 7277380], // 7277380 vuoden 2015 ensimm‰inen ‰‰nestys
        each [Result] <> null,
        each [Result = try GetData([pkStartValue]+100) otherwise null, pkStartValue = [pkStartValue]+100],
        each [Result]),
    
    
    ToTable = Table.FromList(Output, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    #"Expanded Column1" = Table.ExpandTableColumn(ToTable, "Column1", {"EdustajaId", "AanestysId", "EdustajaEtunimi", "EdustajaSukunimi", "EdustajaHenkiloNumero", "EdustajaRyhmaLyhenne", "EdustajaAanestys", "Imported"}, {"EdustajaId", "AanestysId", "EdustajaEtunimi", "EdustajaSukunimi", "EdustajaHenkiloNumero", "EdustajaRyhmaLyhenne", "EdustajaAanestys", "Imported"}),
    #"Filtered Rows" = Table.SelectRows(#"Expanded Column1", each ([AanestysId] <> null))

in
    #"Filtered Rows"