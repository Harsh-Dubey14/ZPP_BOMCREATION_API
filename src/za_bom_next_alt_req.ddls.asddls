@EndUserText.label: 'Get Next Alternate BOM Request'
define abstract entity ZA_BOM_NEXT_ALT_REQ
{
  Material : abap.char(40);
  Plant    : abap.char(4);
  BomUsage : abap.char(1);
}
