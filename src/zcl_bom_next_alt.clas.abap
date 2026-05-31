CLASS zcl_bom_next_alt DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES: BEGIN OF ty_request,
             material  TYPE i_product-product,
             plant     TYPE i_plant-Plant,
             bom_usage TYPE c LENGTH 1,
           END OF ty_request.

    TYPES: BEGIN OF ty_response,
             material     TYPE i_product-product,
             plant        TYPE i_plant-Plant,
             bom_usage    TYPE c LENGTH 1,
             next_alt_bom TYPE c LENGTH 2,
             success      TYPE abap_boolean,
             message      TYPE c LENGTH 255,
           END OF ty_response.

    CLASS-METHODS get_next_alt_bom
      IMPORTING
        is_request         TYPE ty_request
      RETURNING
        VALUE(rs_response) TYPE ty_response.

ENDCLASS.



CLASS ZCL_BOM_NEXT_ALT IMPLEMENTATION.


  METHOD get_next_alt_bom.

    DATA lv_max_alt_i TYPE i VALUE 0.
    DATA lv_next_i    TYPE i.

    rs_response-material  = is_request-material.
    rs_response-plant     = is_request-plant.
    rs_response-bom_usage = is_request-bom_usage.

    IF is_request-material IS INITIAL.
      rs_response-success = abap_false.
      rs_response-message = 'Material is mandatory'.
      RETURN.
    ENDIF.

    IF is_request-plant IS INITIAL.
      rs_response-success = abap_false.
      rs_response-message = 'Plant is mandatory'.
      RETURN.
    ENDIF.

    IF is_request-bom_usage IS INITIAL.
      rs_response-success = abap_false.
      rs_response-message = 'BOM Usage is mandatory'.
      RETURN.
    ENDIF.

    SELECT BillOfMaterialVariant
      FROM I_BillOfMaterialTP_2 WITH PRIVILEGED ACCESS
      WHERE Material                   = @is_request-material
        AND Plant                      = @is_request-plant
        AND BillOfMaterialVariantUsage = @is_request-bom_usage
        AND BillOfMaterialCategory     = 'M'
      INTO TABLE @DATA(lt_alt).

    LOOP AT lt_alt INTO DATA(ls_alt).

      DATA(lv_alt_string) = CONV string( ls_alt-BillOfMaterialVariant ).
      CONDENSE lv_alt_string NO-GAPS.

      IF lv_alt_string IS INITIAL.
        CONTINUE.
      ENDIF.

      TRY.
          DATA(lv_alt_i) = CONV i( lv_alt_string ).

          IF lv_alt_i > lv_max_alt_i.
            lv_max_alt_i = lv_alt_i.
          ENDIF.

        CATCH cx_sy_conversion_no_number.
          CONTINUE.
      ENDTRY.

    ENDLOOP.

    IF lv_max_alt_i = 0.

      rs_response-next_alt_bom = '01'.
      rs_response-success      = abap_true.
      rs_response-message      = 'No existing alternate BOM found. Next alternate BOM is 01'.
      RETURN.

    ENDIF.

    lv_next_i = lv_max_alt_i + 1.

    IF lv_next_i > 99.
      rs_response-success = abap_false.
      rs_response-message = |No next alternate BOM available. Highest existing alternate is { lv_max_alt_i }|.
      RETURN.
    ENDIF.

    rs_response-next_alt_bom = |{ lv_next_i WIDTH = 2 PAD = '0' ALIGN = RIGHT }|.
    rs_response-success      = abap_true.
    rs_response-message      = |Next alternate BOM is { rs_response-next_alt_bom }|.

  ENDMETHOD.
ENDCLASS.
