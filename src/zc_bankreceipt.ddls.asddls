@Metadata.allowExtensions: true
@EndUserText.label: '###GENERATED Core Data Service Entity'
@AccessControl.authorizationCheck: #NOT_REQUIRED
define root view entity ZC_BANKRECEIPT
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
  Errorlog,  
  AccountingDocument,
  Plant,
  Createon,
  CreatedBy,
  CreatedAt,
  LocalLastChangedBy,
  LocalLastChangedAt,
  LastChangedAt
  
}
where IsPosted = '' and IsDeleted = ''
