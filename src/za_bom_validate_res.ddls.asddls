@EndUserText.label: 'Validate Material Plant Response'
define abstract entity ZA_BOM_VALIDATE_RES
{
  Material : abap.char(40);
  Plant    : abap.char(4);
  IsValid  : abap_boolean;
  BaseUnit : abap.unit(3);
  Message  : abap.char(255);
}
