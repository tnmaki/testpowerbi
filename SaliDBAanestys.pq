let
    GetData = (page as number) => 
        let
            SaliDBAanestys = 
                Json.Document(
                    Web.Contents(
                        "http://avoindata.eduskunta.fi/api/v1/tables/SaliDBAanestys/rows?perPage=100&page=0", [Query=[page=Number.ToText(page)]])
                    ), // edellä Chris Webbin temput Web.Contents query optionsin avulla!!
            ResultAll = if SaliDBAanestys[rowCount] > 0 
                            then Table.Combine(List.Transform(SaliDBAanestys[rowData], each Table.FromRows({_}, SaliDBAanestys [columnNames]))) // JSONista listaksi
                            else null, // jos rowCount 0, niin palautetaan null
            ResultFI = Table.SelectRows(ResultAll, each ([KieliId] <> "2")) // Vain suomenkieliset
        in
            ResultFI,
    
    Output = List.Generate( ()=>
        [Result = try GetData(0) otherwise null, Page = 0],
        each [Result] <> null,
        each [Result = try GetData([Page]+1) otherwise null, Page = [Page]+1],
        each [Result]),
    
    
    ToTable = Table.FromList(Output, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    Expand = Table.ExpandTableColumn(ToTable, "Column1", {"AanestysId", "KieliId", "IstuntoVPVuosi", "IstuntoNumero", "IstuntoPvm", "IstuntoIlmoitettuAlkuaika", "IstuntoAlkuaika", "PJOtsikko", "AanestysNumero", "AanestysAlkuaika", "AanestysLoppuaika", "AanestysMitatoity", "AanestysOtsikko", "AanestysLisaOtsikko", "PaaKohtaTunniste", "PaaKohtaOtsikko", "PaaKohtaHuomautus", "KohtaKasittelyOtsikko", "KohtaKasittelyVaihe", "KohtaJarjestys", "KohtaTunniste", "KohtaOtsikko", "KohtaHuomautus", "AanestysTulosJaa", "AanestysTulosEi", "AanestysTulosTyhjia", "AanestysTulosPoissa", "AanestysTulosYhteensa", "Url", "AanestysPoytakirja", "AanestysPoytakirjaUrl", "AanestysValtiopaivaasia", "AanestysValtiopaivaasiaUrl", "AliKohtaTunniste", "Imported"}, {"AanestysId", "KieliId", "IstuntoVPVuosi", "IstuntoNumero", "IstuntoPvm", "IstuntoIlmoitettuAlkuaika", "IstuntoAlkuaika", "PJOtsikko", "AanestysNumero", "AanestysAlkuaika", "AanestysLoppuaika", "AanestysMitatoity", "AanestysOtsikko", "AanestysLisaOtsikko", "PaaKohtaTunniste", "PaaKohtaOtsikko", "PaaKohtaHuomautus", "KohtaKasittelyOtsikko", "KohtaKasittelyVaihe", "KohtaJarjestys", "KohtaTunniste", "KohtaOtsikko", "KohtaHuomautus", "AanestysTulosJaa", "AanestysTulosEi", "AanestysTulosTyhjia", "AanestysTulosPoissa", "AanestysTulosYhteensa", "Url", "AanestysPoytakirja", "AanestysPoytakirjaUrl", "AanestysValtiopaivaasia", "AanestysValtiopaivaasiaUrl", "AliKohtaTunniste", "Imported"}),
    #"Changed Type" = Table.TransformColumnTypes(Expand,{{"IstuntoVPVuosi", Int64.Type}, {"KieliId", Int64.Type}, {"AanestysId", Int64.Type}, {"IstuntoNumero", Int64.Type}}),
    #"Filtered Rows" = Table.SelectRows(#"Changed Type", each [IstuntoVPVuosi] > 2014),
    #"Added Custom" = Table.AddColumn(#"Filtered Rows", "Äänestysotsikko ja -kohta", each [KohtaOtsikko] & " - " & [AanestysOtsikko]),
    #"Added Custom1" = Table.AddColumn(#"Added Custom", "Istuntokuukausi", each Date.Month([IstuntoPvm])),
    #"Removed Columns" = Table.RemoveColumns(#"Added Custom1",{"Istuntokuukausi"}),
    #"Added Custom2" = Table.AddColumn(#"Removed Columns" , "Äänestysotsikko eka kirjain", each Text.Start([#"Äänestysotsikko ja -kohta"],1))
in
    #"Added Custom2"