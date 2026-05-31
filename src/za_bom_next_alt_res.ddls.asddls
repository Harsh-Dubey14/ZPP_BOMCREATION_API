@EndUserText.label: 'Get Next Alternate BOM Response'
define abstract entity ZA_BOM_NEXT_ALT_RES
{
  Material   : abap.char(40);
  Plant      : abap.char(4);
  BomUsage   : abap.char(1);
  NextAltBom : abap.char(2);
  Success    : abap_boolean;
  Message    : abap.char(255);
}
