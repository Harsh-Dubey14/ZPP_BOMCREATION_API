CLASS zcl_uom_nzr_helper DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    CLASS-METHODS normalize_uom
      IMPORTING
        VALUE(iv_uom) TYPE zmeins
      RETURNING
        VALUE(rv_uom) TYPE zmeins.

ENDCLASS.



CLASS ZCL_UOM_NZR_HELPER IMPLEMENTATION.


  METHOD normalize_uom.

    DATA: lv_source_uom TYPE zmeins,
          lv_target_uom TYPE zmeins.

    CLEAR rv_uom.

    IF iv_uom IS INITIAL.
      RETURN.
    ENDIF.

    lv_source_uom = iv_uom.
    TRANSLATE lv_source_uom TO UPPER CASE.
    CONDENSE lv_source_uom NO-GAPS.

    "Default return same UOM
    rv_uom = lv_source_uom.

    SELECT SINGLE TargetUOM
      FROM ZC_TBUOM_NZR
      WHERE SourceUOM = @lv_source_uom
      INTO @lv_target_uom.

    IF sy-subrc = 0 AND lv_target_uom IS NOT INITIAL.
      rv_uom = lv_target_uom.
    ENDIF.

  ENDMETHOD.
ENDCLASS.
