CLASS zcl_bom_change_api DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES: BEGIN OF ty_item,
             bill_of_material TYPE string,
             bom_category     TYPE string,
             alt_bom          TYPE string,
             bom_usage        TYPE string,
             material         TYPE string,
             plant            TYPE string,

             item_node_number TYPE string,
             item_number      TYPE string,

             component        TYPE string,
             quantity         TYPE p LENGTH 16 DECIMALS 3,
             uom              TYPE string,

             item_text        TYPE string,
             sort_string      TYPE string,

             change_mode      TYPE c LENGTH 1,
           END OF ty_item.

    TYPES: BEGIN OF ty_result,
             success      TYPE abap_boolean,
             status       TYPE c LENGTH 20,
             message      TYPE c LENGTH 255,
             api_response TYPE string,
           END OF ty_result.

    CLASS-METHODS change_bom_item
      IMPORTING
        is_item          TYPE ty_item
      RETURNING
        VALUE(rs_result) TYPE ty_result.

  PRIVATE SECTION.

    CONSTANTS lc_bom_api_base TYPE string
      VALUE '/sap/opu/odata/sap/API_BILL_OF_MATERIAL_SRV;v=0002'.

    CLASS-METHODS build_item_path
      IMPORTING
        is_item        TYPE ty_item
      RETURNING
        VALUE(rv_path) TYPE string.

    CLASS-METHODS build_patch_payload
      IMPORTING
        is_item        TYPE ty_item
      RETURNING
        VALUE(rv_json) TYPE string.

    CLASS-METHODS build_post_path
      RETURNING
        VALUE(rv_path) TYPE string.

    CLASS-METHODS build_post_payload
      IMPORTING
        is_item        TYPE ty_item
      RETURNING
        VALUE(rv_json) TYPE string.

    CLASS-METHODS escape_json
      IMPORTING
        iv_value        TYPE string
      RETURNING
        VALUE(rv_value) TYPE string.

    CLASS-METHODS escape_url_key
      IMPORTING
        iv_value        TYPE string
      RETURNING
        VALUE(rv_value) TYPE string.

ENDCLASS.



CLASS zcl_bom_change_api IMPLEMENTATION.

  METHOD change_bom_item.

    TRY.

        DATA(lv_mode) = is_item-change_mode.

        IF lv_mode IS INITIAL.
          lv_mode = 'U'.
        ENDIF.

        TRANSLATE lv_mode TO UPPER CASE.

        IF lv_mode <> 'U' AND lv_mode <> 'I' AND lv_mode <> 'D'.
          rs_result-success = abap_false.
          rs_result-status  = 'ERROR'.
          rs_result-message = 'Only update mode U, insert mode I and delete mode D are supported'.
          RETURN.
        ENDIF.

        IF is_item-bill_of_material IS INITIAL.
          rs_result-success = abap_false.
          rs_result-status  = 'ERROR'.
          rs_result-message = 'BOM number is mandatory'.
          RETURN.
        ENDIF.

        IF is_item-alt_bom IS INITIAL.
          rs_result-success = abap_false.
          rs_result-status  = 'ERROR'.
          rs_result-message = 'Alternative BOM is mandatory'.
          RETURN.
        ENDIF.

        IF is_item-material IS INITIAL.
          rs_result-success = abap_false.
          rs_result-status  = 'ERROR'.
          rs_result-message = 'Material is mandatory'.
          RETURN.
        ENDIF.

        IF is_item-plant IS INITIAL.
          rs_result-success = abap_false.
          rs_result-status  = 'ERROR'.
          rs_result-message = 'Plant is mandatory'.
          RETURN.
        ENDIF.

        IF lv_mode <> 'I' AND is_item-item_node_number IS INITIAL.
          rs_result-success = abap_false.
          rs_result-status  = 'ERROR'.
          rs_result-message = 'BOM item node number is mandatory for update/delete'.
          RETURN.
        ENDIF.

        "For update/insert, item data is required.
        "For delete, only item key fields are required.
        IF lv_mode <> 'D'.

          IF is_item-item_number IS INITIAL.
            rs_result-success = abap_false.
            rs_result-status  = 'ERROR'.
            rs_result-message = 'BOM item number is mandatory'.
            RETURN.
          ENDIF.

          IF is_item-component IS INITIAL.
            rs_result-success = abap_false.
            rs_result-status  = 'ERROR'.
            rs_result-message = 'BOM item component is mandatory'.
            RETURN.
          ENDIF.

          IF is_item-quantity IS INITIAL.
            rs_result-success = abap_false.
            rs_result-status  = 'ERROR'.
            rs_result-message = 'BOM item quantity is mandatory'.
            RETURN.
          ENDIF.

          IF is_item-uom IS INITIAL.
            rs_result-success = abap_false.
            rs_result-status  = 'ERROR'.
            rs_result-message = 'BOM item unit is mandatory'.
            RETURN.
          ENDIF.

        ENDIF.

        DATA lv_path        TYPE string.
        DATA lv_payload     TYPE string.
        DATA ls_http_result TYPE zcl_bom_put_helper=>ty_http_result.

        CASE lv_mode.

          WHEN 'U'.

            lv_path    = build_item_path( is_item ).
            lv_payload = build_patch_payload( is_item ).

            IF lv_path IS INITIAL.
              rs_result-success      = abap_false.
              rs_result-status       = 'ERROR'.
              rs_result-message      = 'PATCH path could not be built'.
              rs_result-api_response = lv_payload.
              RETURN.
            ENDIF.

            IF lv_payload IS INITIAL.
              rs_result-success = abap_false.
              rs_result-status  = 'ERROR'.
              rs_result-message = 'PATCH payload could not be built'.
              RETURN.
            ENDIF.

            ls_http_result = zcl_bom_put_helper=>execute_patch(
              iv_path    = lv_path
              iv_payload = lv_payload
            ).

          WHEN 'I'.

            lv_path    = build_post_path( ).
            lv_payload = build_post_payload( is_item ).

            IF lv_path IS INITIAL.
              rs_result-success      = abap_false.
              rs_result-status       = 'ERROR'.
              rs_result-message      = 'POST path could not be built'.
              rs_result-api_response = lv_payload.
              RETURN.
            ENDIF.

            IF lv_payload IS INITIAL.
              rs_result-success = abap_false.
              rs_result-status  = 'ERROR'.
              rs_result-message = 'POST payload could not be built'.
              RETURN.
            ENDIF.

            ls_http_result = zcl_bom_put_helper=>execute_post(
              iv_path    = lv_path
              iv_payload = lv_payload
            ).

          WHEN 'D'.

            lv_path = build_item_path( is_item ).

            IF lv_path IS INITIAL.
              rs_result-success = abap_false.
              rs_result-status  = 'ERROR'.
              rs_result-message = 'DELETE path could not be built'.
              RETURN.
            ENDIF.

            ls_http_result = zcl_bom_put_helper=>execute_delete(
              iv_path = lv_path
            ).

        ENDCASE.

        rs_result-success = ls_http_result-success.

        IF lv_mode = 'D'.
          rs_result-api_response =
            |Mode: { lv_mode } Path: { lv_path } Response: { ls_http_result-response }|.
        ELSE.
          rs_result-api_response =
            |Mode: { lv_mode } Path: { lv_path } Payload: { lv_payload } Response: { ls_http_result-response }|.
        ENDIF.

        IF ls_http_result-success = abap_true.

          rs_result-status = 'SUCCESS'.

          CASE lv_mode.
            WHEN 'U'.
              rs_result-message = |BOM item updated successfully. { ls_http_result-message }|.
            WHEN 'I'.
              rs_result-message = |BOM item added successfully. { ls_http_result-message }|.
            WHEN 'D'.
              rs_result-message = |BOM item deleted successfully. { ls_http_result-message }|.
          ENDCASE.

        ELSE.

          rs_result-status = 'ERROR'.

          CASE lv_mode.
            WHEN 'U'.
              rs_result-message = |BOM item update failed. { ls_http_result-message }|.
            WHEN 'I'.
              rs_result-message = |BOM item add failed. { ls_http_result-message }|.
            WHEN 'D'.
              rs_result-message = |BOM item delete failed. { ls_http_result-message }|.
          ENDCASE.

        ENDIF.

      CATCH cx_root INTO DATA(lx_error).

        rs_result-success = abap_false.
        rs_result-status  = 'ERROR'.
        rs_result-message = zcl_bom_put_helper=>build_exception_message( lx_error ).

    ENDTRY.

  ENDMETHOD.



  METHOD build_item_path.

    DATA(lv_bom)      = is_item-bill_of_material.
    DATA(lv_cat)      = COND string(
                          WHEN is_item-bom_category IS INITIAL
                          THEN 'M'
                          ELSE is_item-bom_category
                        ).
    DATA(lv_alt)      = is_item-alt_bom.
    DATA(lv_material) = is_item-material.
    DATA(lv_plant)    = is_item-plant.
    DATA(lv_node)     = is_item-item_node_number.

    CONDENSE: lv_bom NO-GAPS,
              lv_cat NO-GAPS,
              lv_alt NO-GAPS,
              lv_material NO-GAPS,
              lv_plant NO-GAPS,
              lv_node NO-GAPS.

    TRANSLATE lv_cat TO UPPER CASE.

    rv_path =
      lc_bom_api_base &&
      `/MaterialBOMItem(` &&
      `BillOfMaterial='` && escape_url_key( lv_bom ) && `',` &&
      `BillOfMaterialCategory='` && escape_url_key( lv_cat ) && `',` &&
      `BillOfMaterialVariant='` && escape_url_key( lv_alt ) && `',` &&
      `BillOfMaterialVersion='',` &&
      `BillOfMaterialItemNodeNumber='` && escape_url_key( lv_node ) && `',` &&
      `HeaderChangeDocument='',` &&
      `Material='` && escape_url_key( lv_material ) && `',` &&
      `Plant='` && escape_url_key( lv_plant ) && `'` &&
      `)`.

  ENDMETHOD.



  METHOD build_patch_payload.

    DATA(lv_component) = is_item-component.
    DATA(lv_qty)       = |{ is_item-quantity }|.
    DATA(lv_uom)       = is_item-uom.
    DATA(lv_sort)      = is_item-sort_string.
    DATA lv_nm_uom     TYPE meins.

    CONDENSE: lv_component NO-GAPS,
              lv_qty NO-GAPS,
              lv_uom NO-GAPS.

    TRANSLATE lv_uom TO UPPER CASE.

    lv_nm_uom = zcl_uom_nzr_helper=>normalize_uom(
                  CONV meins( lv_uom )
                ).

    CONDENSE lv_nm_uom NO-GAPS.
    TRANSLATE lv_nm_uom TO UPPER CASE.

    rv_json =
      `{` &&
        `"d":{` &&
          `"BillOfMaterialComponent":"` && escape_json( lv_component ) && `",` &&
          `"BillOfMaterialItemQuantity":"` && lv_qty && `",` &&
          `"BillOfMaterialItemUnit":"` && escape_json( CONV string( lv_nm_uom ) ) && `",` &&
          `"BOMItemSorter":"` && escape_json( lv_sort ) && `"` &&
        `}` &&
      `}`.

  ENDMETHOD.



  METHOD build_post_path.

    rv_path = lc_bom_api_base && `/MaterialBOMItem`.

  ENDMETHOD.



  METHOD build_post_payload.

    DATA(lv_bom)       = is_item-bill_of_material.
    DATA(lv_cat)       = COND string(
                           WHEN is_item-bom_category IS INITIAL
                           THEN 'M'
                           ELSE is_item-bom_category
                         ).
    DATA(lv_alt)       = is_item-alt_bom.
    DATA(lv_material)  = is_item-material.
    DATA(lv_plant)     = is_item-plant.
    DATA(lv_node)      = is_item-item_node_number.
    DATA(lv_item_no)   = is_item-item_number.
    DATA(lv_component) = is_item-component.
    DATA(lv_qty)       = |{ is_item-quantity }|.
    DATA(lv_uom)       = is_item-uom.
    DATA(lv_text)      = is_item-item_text.
    DATA(lv_sort)      = is_item-sort_string.
    DATA lv_nm_uom     TYPE meins.

    CONDENSE: lv_bom NO-GAPS,
              lv_cat NO-GAPS,
              lv_alt NO-GAPS,
              lv_material NO-GAPS,
              lv_plant NO-GAPS,
              lv_node NO-GAPS,
              lv_item_no NO-GAPS,
              lv_component NO-GAPS,
              lv_qty NO-GAPS,
              lv_uom NO-GAPS.

    TRANSLATE: lv_cat TO UPPER CASE,
               lv_uom TO UPPER CASE.

    lv_nm_uom = zcl_uom_nzr_helper=>normalize_uom(
                  CONV meins( lv_uom )
                ).

    CONDENSE lv_nm_uom NO-GAPS.
    TRANSLATE lv_nm_uom TO UPPER CASE.

    rv_json =
      `{` &&
        `"d":{` &&
          `"BillOfMaterial":"` && escape_json( lv_bom ) && `",` &&
          `"BillOfMaterialCategory":"` && escape_json( lv_cat ) && `",` &&
          `"BillOfMaterialVariant":"` && escape_json( lv_alt ) && `",` &&
          `"BillOfMaterialVersion":"",` &&
          `"HeaderChangeDocument":"",` &&
          `"Material":"` && escape_json( lv_material ) && `",` &&
          `"Plant":"` && escape_json( lv_plant ) && `",` &&
          `"BillOfMaterialItemNumber":"` && escape_json( lv_item_no ) && `",` &&
          `"BillOfMaterialItemCategory":"L",` &&
          `"BillOfMaterialComponent":"` && escape_json( lv_component ) && `",` &&
          `"BillOfMaterialItemQuantity":"` && lv_qty && `",` &&
          `"BillOfMaterialItemUnit":"` && escape_json( CONV string( lv_nm_uom ) ) && `",` &&
          `"BOMItemDescription":"` && escape_json( lv_text ) && `",` &&
          `"BOMItemSorter":"` && escape_json( lv_sort ) && `",` &&
          `"IsProductionRelevant":true` &&
        `}` &&
      `}`.

  ENDMETHOD.



  METHOD escape_json.

    rv_value = iv_value.

    REPLACE ALL OCCURRENCES OF `\` IN rv_value WITH `\\`.
    REPLACE ALL OCCURRENCES OF `"` IN rv_value WITH `\"`.

  ENDMETHOD.



  METHOD escape_url_key.

    rv_value = iv_value.

    "First encode percent, otherwise generated %2F can become wrong later
    REPLACE ALL OCCURRENCES OF `%` IN rv_value WITH `%25`.

    "OData key quote escaping
    REPLACE ALL OCCURRENCES OF `'` IN rv_value WITH `''`.

    "URL unsafe characters
    REPLACE ALL OCCURRENCES OF `/` IN rv_value WITH `%2F`.
    REPLACE ALL OCCURRENCES OF ` ` IN rv_value WITH `%20`.
    REPLACE ALL OCCURRENCES OF `#` IN rv_value WITH `%23`.
    REPLACE ALL OCCURRENCES OF `&` IN rv_value WITH `%26`.
    REPLACE ALL OCCURRENCES OF `+` IN rv_value WITH `%2B`.

  ENDMETHOD.

ENDCLASS.
