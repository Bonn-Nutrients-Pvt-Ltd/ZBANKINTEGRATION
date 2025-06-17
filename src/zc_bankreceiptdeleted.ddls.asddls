@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Deleted Bank Receipts'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define root view entity ZC_BANKRECEIPTDELETED 
provider contract transactional_query
  as projection on ZR_BANKRECEIPT
{
  key Id,
  Transactionid,
  Remittername,
  Fromaccountnumber,
  Frombankname,
  Utr,
  Virtualaccount,
  Amount,
  AccountId,
  Transfermode,
  Creditdatetime,
  Ipfrom,
  CompanyCode,
  AccountingDocument,
  Plant,
  Createon,
  CreatedBy,
  CreatedAt,
  LocalLastChangedBy,
  LocalLastChangedAt,
  LastChangedAt
  
}
where IsPosted = '' and IsDeleted = 'X'
