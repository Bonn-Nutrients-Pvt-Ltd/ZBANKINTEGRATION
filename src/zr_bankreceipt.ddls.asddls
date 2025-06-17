@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@EndUserText.label: '###GENERATED Core Data Service Entity'
define root view entity ZR_BANKRECEIPT
  as select from zbankreceipt
{
  key id as Id,
  transactionid as Transactionid,
  remittername as Remittername,
  fromaccountnumber as Fromaccountnumber,
  frombankname as Frombankname,
  utr as Utr,
  virtualaccount as Virtualaccount,
  amount as Amount,
  transfermode as Transfermode,
  creditdatetime as Creditdatetime,
  ipfrom as Ipfrom,
  account_id as AccountId,
  createon as Createon,
  company_code as CompanyCode,
  accountingdocument as AccountingDocument,
  plant as Plant,
  isdeleted as IsDeleted,
  isposted  as IsPosted,
  errorlog as Errorlog,
  @Semantics.user.createdBy: true
  created_by as CreatedBy,
  @Semantics.systemDateTime.createdAt: true
  created_at as CreatedAt,
  @Semantics.user.localInstanceLastChangedBy: true
  local_last_changed_by as LocalLastChangedBy,
  @Semantics.systemDateTime.localInstanceLastChangedAt: true
  local_last_changed_at as LocalLastChangedAt,
  @Semantics.systemDateTime.lastChangedAt: true
  last_changed_at as LastChangedAt
  
}
