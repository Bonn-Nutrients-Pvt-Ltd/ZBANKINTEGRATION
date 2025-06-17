@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Posted Bank Receipts'
@Metadata.allowExtensions: true
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define root view entity ZC_BANKRECEIPTPOSTED   
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
where IsPosted = 'X' and IsDeleted = ''
