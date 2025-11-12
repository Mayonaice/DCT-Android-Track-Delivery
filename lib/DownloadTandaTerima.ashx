<%@ WebHandler Language="VB" Class="DownloadTandaTerima" %>

Imports System
Imports System.Web
Imports OfficeOpenXml
Imports System.Data
Imports System.IO
Imports Microsoft.Reporting.WebForms
Imports System.Configuration
Imports SelectPdf
Imports System.Net
Imports System.Net.Http


Public Class DownloadTandaTerima : Implements IHttpHandler, System.Web.SessionState.IReadOnlySessionState

    Public Sub ProcessRequest(ByVal context As HttpContext) Implements IHttpHandler.ProcessRequest

        Dim SeqNo As String = context.Request.QueryString("SeqNo")
        Dim DeliveryNo As String = context.Request.QueryString("DeliveryNo")

        
        If (SeqNo Is Nothing OrElse SeqNo.Trim() = "") AndAlso (Not String.IsNullOrEmpty(DeliveryNo)) Then
            Try
                Using oHelper As New clsSQLHelper
                    oHelper.CommandType = CommandType.Text

                    oHelper.CommandText = "SELECT TOP (1) SeqNo FROM [ADVDELIVERY].[dbo].[TRACK_Delivery] WHERE DeliveryNo = @DeliveryNo ORDER BY SeqNo DESC"
                    oHelper.AddParameter("@DeliveryNo", DeliveryNo, SqlDbType.VarChar)
                    Dim dtLookup As DataTable = oHelper.ExecuteDataTable
                    If dtLookup IsNot Nothing AndAlso dtLookup.Rows.Count > 0 Then
                        SeqNo = Convert.ToString(dtLookup.Rows(0)("SeqNo"))
                    Else

                        context.Response.StatusCode = CInt(HttpStatusCode.NotFound)
                        context.Response.Write("DeliveryNo tidak ditemukan: " & DeliveryNo)
                        Return
                    End If
                End Using
            Catch ex As Exception

                context.Response.StatusCode = CInt(HttpStatusCode.BadRequest)
                context.Response.Write("Gagal mencari SeqNo dari DeliveryNo: " & ex.Message)
                Return
            End Try
        End If

        If SeqNo Is Nothing OrElse SeqNo.Trim() = "" Then
            context.Response.StatusCode = CInt(HttpStatusCode.BadRequest)
            context.Response.Write("Parameter SeqNo atau DeliveryNo wajib diisi.")
            Return
        End If

        GetTandaTerima(SeqNo, context)

    End Sub


    Private Sub GetTandaTerima(ByVal SeqNo As String, ByRef Context As HttpContext)
        Dim DtHead As New DataTable
        Dim DtBarang As New DataTable
        Dim DtPenerima As New DataTable

        Using oHelper As New clsSQLHelper
            oHelper.CommandType = CommandType.StoredProcedure
            oHelper.CommandText = "[TRACK_SP_Delivery_GetReport]"
            oHelper.AddParameter("@SeqNo", SeqNo, SqlDbType.VarChar)
            oHelper.AddParameter("@Type", "TandaTerima", SqlDbType.VarChar)
            oHelper.AddParameter("@Act", "Head", SqlDbType.VarChar)
            DtHead = oHelper.ExecuteDataTable
        End Using
        If DtHead Is Nothing OrElse DtHead.Rows.Count = 0 Then
            Context.Response.StatusCode = CInt(HttpStatusCode.NotFound)
            Context.Response.Write("Data tidak ditemukan untuk SeqNo: " & SeqNo)
            Return
        End If

        Dim FileName As String = DtHead.Rows(0)("FileName").ToString
        Dim HtmlString As String = ""


        HtmlString &= " <!DOCTYPE html> " & vbCrLf
        HtmlString &= " <html lang=""en""> " & vbCrLf
        HtmlString &= " <head> " & vbCrLf
        HtmlString &= "     <title>FORM TANDA TERIMA</title> " & vbCrLf
        HtmlString &= " <style type=""text/css"" >" & vbCrLf
        HtmlString &= " p {  margin-top:    0; "
        HtmlString &= "     margin-bottom:    1rem; "
        HtmlString &= "     } "
        HtmlString &= " *  {  box-sizing: border-box; } "
        HtmlString &= " .text-center { "
        HtmlString &= "       text-align: center !important; "
        HtmlString &= "     } "
        HtmlString &= " body { "
        HtmlString &= "      font-family:system-ui, -apple-system, ""Segoe UI"", Roboto, ""Helvetica Neue"", Arial, ""Noto Sans"", ""Liberation Sans"", sans-serif, ""Apple Color Emoji"", ""Segoe UI Emoji"", ""Segoe UI Symbol"", ""Noto Color Emoji"";"
        HtmlString &= "      font-size:1rem; "
        HtmlString &= "      font-weight: 400; "
        HtmlString &= "      line-height: 1.5 ; "
        HtmlString &= "      color: #212529; "
        HtmlString &= "      -webkit-text-size-adjust: 100%; "
        HtmlString &= "     } "
        HtmlString &= " .table {"
        HtmlString &= "    caption-side: bottom;"
        HtmlString &= "    border-collapse: collapse;"
        HtmlString &= " }   "
        HtmlString &= " table { "
        HtmlString &= "  caption-side: bottom;"
        HtmlString &= "  border-collapse: collapse;"
        HtmlString &= "  margin-bottom: 1rem; "
        HtmlString &= " } "
        HtmlString &= "   .table-bordered > :not(caption) > * { "
        HtmlString &= "  border-width: 1px  0  ; "
        HtmlString &= " } "
        HtmlString &= " .table > :not(caption) > * > * { "
        HtmlString &= "  padding: 0.5rem 0.5rem; "
        HtmlString &= "  background-color: transparent; "
        HtmlString &= "  border-bottom-width: 1px; "
        HtmlString &= "  box-shadow: inset 0 0 0 9999px transparent; "
        HtmlString &= " } "
        HtmlString &= " .table-bordered > :not(caption) > * > * { "
        HtmlString &= "  border-width: 0 1px; "
        HtmlString &= " } "
        HtmlString &= " .border-secondary { "
        HtmlString &= "     border-color:   #6c757d !important; "
        HtmlString &= " } "
        HtmlString &= "  tbody, td, tfoot, th, thead, tr {"
        HtmlString &= " border-color: inherit;"
        HtmlString &= " border-style: solid;"
        HtmlString &= " border-width: 0;"
        HtmlString &= " } "
        HtmlString &= " .p-2 { "
        HtmlString &= " padding: 0.5rem !important;"
        HtmlString &= " } "
        HtmlString &= ".border-secondary { "
        HtmlString &= " border-color: #6c757d !important; "
        HtmlString &= " } "
        HtmlString &= " .border { "
        HtmlString &= " border: 1px solid #dee2e6 !important;"
        HtmlString &= " } "
        HtmlString &= " .container  {"
        HtmlString &= " width: 100%;"
        HtmlString &= " padding-right: var(1.5rem, 0.75rem);"
        HtmlString &= " padding-left: var(1.5rem, 0.75rem);"
        HtmlString &= "  margin-right: auto;"
        HtmlString &= "  margin-left: auto;"
        HtmlString &= "  max-width:   1140px;"
        HtmlString &= " } "
        HtmlString &= " .column {"
        HtmlString &= "   float: left ;"
        HtmlString &= "   width: 33.33%;"
        HtmlString &= "   padding: 15px;"
        HtmlString &= "}"
        HtmlString &= "  .table > tbody {"
        HtmlString &= " vertical-align: inherit;"
        HtmlString &= " } "
        HtmlString &= " @media (min-width: 1400px) {"
        HtmlString &= "  .container, .container-lg, .container-md, .container-sm, .container-xl, .container-xxl { "
        HtmlString &= "  max-width:   1320px; "
        HtmlString &= "  } "
        HtmlString &= " } "
        HtmlString &= " </style> " & vbCrLf
        HtmlString &= " </head> " & vbCrLf
        HtmlString &= " <body style=""font-size:13pt"">" & vbCrLf
        HtmlString &= "   <p style=""text-align: center; font-size:16pt;""> <b> FORM TANDA TERIMA</b></p> "
        HtmlString &= "  <table style=""width: 100%"" border=""0""> "
        HtmlString &= "     <tbody> "
        HtmlString &= "      <tr> "
        HtmlString &= "         <td style=""width: 150px""> Kode Pengiriman</td> "
        HtmlString &= "         <td style=""width: 10px"">:  </td> "
        HtmlString &= "         <td style=""font-weight:bold"">" & DtHead.Rows(0)("DeliveryNo").ToString & "</td> "
        HtmlString &= "     </tr> "
        HtmlString &= "     <tr> "
        HtmlString &= "        <td>Tanggal</td> "
        HtmlString &= "        <td>:</td> "
        HtmlString &= "        <td style=""font-weight:bold""> " & DtHead.Rows(0)("Tanggal").ToString & "</td> "
        HtmlString &= "    </tr> "
        HtmlString &= "    <tr> "
        HtmlString &= "        <td>Dikirim dari</td> "
        HtmlString &= "       <td>:</td> "
        HtmlString &= "       <td style=""font-weight:bold""> " & DtHead.Rows(0)("NamePengirim").ToString & "</td> "
        HtmlString &= "   </tr> "
        HtmlString &= "   <tr> "
        HtmlString &= "       <td>Ditujukan kepada</td> "
        HtmlString &= "       <td>:</td> "
        HtmlString &= "       <td style=""font-weight:bold""> " & DtHead.Rows(0)("NamePenerimaAkhir").ToString & "</td> "
        HtmlString &= "     </tr> "
        HtmlString &= "   </tbody> "
        HtmlString &= "  </table> "
        HtmlString &= " <hr /> "
        HtmlString &= "    <table class="" table  table-bordered border-secondary"" style=""height: 60px; width: 100%""> "
        HtmlString &= "       <tbody> "
        HtmlString &= "          <tr> "
        HtmlString &= "              <td class=""text-center""><strong>NO</strong></td> "
        HtmlString &= "              <td class=""text-center""><strong>NAMA BARANG</strong></td> "
        HtmlString &= "              <td class=""text-center""><strong>JUMLAH</strong></td> "
        HtmlString &= "              <td class=""text-center""><strong>SERIAL NUMBER</strong></td> "
        HtmlString &= "             <td class=""text-center""><strong>DESKRIPSI BARANG</strong></td> "
        HtmlString &= "         </tr> "

        Using oHelper As New clsSQLHelper
            oHelper.CommandType = CommandType.StoredProcedure
            oHelper.CommandText = "[TRACK_SP_Delivery_GetReport]"
            oHelper.AddParameter("@SeqNo", SeqNo, SqlDbType.VarChar)
            oHelper.AddParameter("@Type", "TandaTerima", SqlDbType.VarChar)
            oHelper.AddParameter("@Act", "Barang", SqlDbType.VarChar)
            DtBarang = oHelper.ExecuteDataTable
        End Using

        Dim i As Integer = 0
        If DtBarang.Rows.Count > 0 Then
            For i = 0 To DtBarang.Rows.Count - 1
                HtmlString &= "         <tr> "
                HtmlString &= "             <td class=""text-center"">" & i + 1 & "</td> "
                HtmlString &= "             <td class=""text-center"">" & DtBarang.Rows(i)("ItemName").ToString & "</td> "
                HtmlString &= "             <td class=""text-center"">" & DtBarang.Rows(i)("Qty").ToString & "</td> "
                HtmlString &= "             <td class=""text-center"">" & DtBarang.Rows(i)("SerialNumber").ToString & "</td> "
                HtmlString &= "             <td class=""text-center"">" & DtBarang.Rows(i)("ItemDescription").ToString & "</td> "
                HtmlString &= "         </tr> "
            Next

            For i = i To 9
                HtmlString &= "         <tr> "
                HtmlString &= "             <td class=""text-center"">" & i + 1 & "</td> "
                HtmlString &= "             <td class=""text-center"">&nbsp;</td> "
                HtmlString &= "             <td class=""text-center"">&nbsp;</td> "
                HtmlString &= "             <td class=""text-center"">&nbsp;</td> "
                HtmlString &= "             <td class=""text-center"">&nbsp;</td> "
                HtmlString &= "         </tr> "
            Next
        End If

        HtmlString &= "      </tbody> "
        HtmlString &= "  </table> "
        HtmlString &= "      <div class=""container text-center""> "
        HtmlString &= "         <div class=""row ""> "
        HtmlString &= "            <div class=""column""> "
        HtmlString &= "               <p> <b> Pengirim</b><br /> "
        HtmlString &= DtHead.Rows(0)("NamePengirim").ToString & "<br /> "
        HtmlString &= DtHead.Rows(0)("TanggalPengirim").ToString
        HtmlString &= "             </p> "
        HtmlString &= "         </div> "

        Using oHelper As New clsSQLHelper
            oHelper.CommandType = CommandType.StoredProcedure
            oHelper.CommandText = "[TRACK_SP_Delivery_GetReport]"
            oHelper.AddParameter("@SeqNo", SeqNo, SqlDbType.VarChar)
            oHelper.AddParameter("@Type", "TandaTerima", SqlDbType.VarChar)
            oHelper.AddParameter("@Act", "Perantara", SqlDbType.VarChar)
            DtPenerima = oHelper.ExecuteDataTable
        End Using

        If DtPenerima.Rows.Count > 0 Then
            For i = 0 To DtPenerima.Rows.Count - 1
                HtmlString &= " <div class=""column""> "

                If i = DtPenerima.Rows.Count - 1 Then
                    HtmlString &= " <p>  <b> Penerima</b><br /> "
                Else
                    HtmlString &= " <p>  <b> Perantara</b><br /> "
                End If

                HtmlString &= DtPenerima.Rows(i)("Name").ToString & "<br /> "
                HtmlString &= DtPenerima.Rows(i)("TanggalPenerima").ToString
                HtmlString &= "             </p> "
                HtmlString &= "         </div> "
            Next
        End If


        HtmlString &= "   </div> "
        HtmlString &= " </div>  " & vbCrLf
        HtmlString &= " </body> " & vbCrLf
        HtmlString &= " </html> "


        Dim converter As New HtmlToPdf()
        converter.Options.PdfPageSize = PdfPageSize.A4
        converter.Options.PdfPageOrientation = PdfPageOrientation.Portrait
        converter.Options.MarginTop = 30
        converter.Options.MarginBottom = 0
        converter.Options.MarginLeft = 30
        converter.Options.MarginRight = 30
        converter.Options.EmbedFonts = True
        converter.Options.ExternalLinksEnabled = True
        converter.Options.InternalLinksEnabled = True
        converter.Options.JavaScriptEnabled = True
        converter.Options.CssMediaType = HtmlToPdfCssMediaType.Print


        Dim doc As PdfDocument = converter.ConvertHtmlString(HtmlString)

        doc.Save(Context.Response, False, Replace(FileName, " ", "_") + ".pdf")
        doc.Close()
    End Sub

    Public ReadOnly Property IsReusable() As Boolean Implements IHttpHandler.IsReusable
        Get
            Return False
        End Get
    End Property

End Class