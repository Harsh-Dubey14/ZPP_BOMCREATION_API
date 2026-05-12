@EndUserText.label: 'BOM Automation API'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_BOM_API_QUERY'
define root custom entity ZCE_BOM_API
{
  key ApiId : abap.char(10);

  Material : abap.char(40);
  Plant    : abap.char(4);
  Message  : abap.char(255);
}
