CLASS lhc_zi_bom_hdr_n DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR zi_bom_hdr_n RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR zi_bom_hdr_n RESULT result.

    METHODS createstandardbom FOR DETERMINE ON modify
      IMPORTING keys FOR zi_bom_hdr_n~createstandardbom.

      METHODS SubmitBOM FOR MODIFY
  IMPORTING keys FOR ACTION ZI_BOM_HDR_N~SubmitBOM
  RESULT result.

ENDCLASS.

CLASS lhc_zi_bom_hdr_n IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

*METHOD CreateStandardBOM.
*
*  READ ENTITIES OF ZI_BOM_HDR_N IN LOCAL MODE
*    ENTITY ZI_BOM_HDR_N
*    ALL FIELDS
*    WITH CORRESPONDING #( keys )
*    RESULT DATA(lt_header).
*
*  READ ENTITIES OF ZI_BOM_HDR_N IN LOCAL MODE
*    ENTITY ZI_BOM_HDR_N BY \_Item
*    ALL FIELDS
*    WITH CORRESPONDING #( keys )
*    RESULT DATA(lt_item).
*
*  LOOP AT lt_header INTO DATA(ls_header).
*
*    DATA(lv_item_count) = REDUCE i(
*      INIT lv_count = 0
*      FOR ls_item IN lt_item
*      WHERE ( BomId = ls_header-BomId )
*      NEXT lv_count = lv_count + 1
*    ).
*
*    MODIFY ENTITIES OF ZI_BOM_HDR_N IN LOCAL MODE
*      ENTITY ZI_BOM_HDR_N
*      UPDATE FIELDS ( Status Message ApiResponse )
*      WITH VALUE #(
*        (
*          BomId       = ls_header-BomId
*          Status      = 'CREATED'
*          Message     = |BOM request created. Item count: { lv_item_count }|
*          ApiResponse = |Ready for SubmitBOM action|
*        )
*      ).
*
*  ENDLOOP.
*
*ENDMETHOD.
METHOD CreateStandardBOM.

  READ ENTITIES OF ZI_BOM_HDR_N IN LOCAL MODE
    ENTITY ZI_BOM_HDR_N
    ALL FIELDS
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_header).

  READ ENTITIES OF ZI_BOM_HDR_N IN LOCAL MODE
    ENTITY ZI_BOM_HDR_N BY \_Item
    ALL FIELDS
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_item).

  LOOP AT lt_header INTO DATA(ls_header).

    DATA lt_bom_item TYPE zcl_bom_create_api=>ty_item_tab.

    LOOP AT lt_item INTO DATA(ls_item)
      WHERE BomId = ls_header-BomId.

      APPEND VALUE #(
        item_no       = ls_item-ItemNo
        item_category = ls_item-ItemCategory
        component     = ls_item-Component
        quantity      = ls_item-Quantity
        uom           = ls_item-Uom
        item_text     = ls_item-ItemText
      ) TO lt_bom_item.

    ENDLOOP.

    IF lt_bom_item IS INITIAL.

      MODIFY ENTITIES OF ZI_BOM_HDR_N IN LOCAL MODE
        ENTITY ZI_BOM_HDR_N
        UPDATE FIELDS ( Status Message ApiResponse )
        WITH VALUE #(
          (
            BomId       = ls_header-BomId
            Status      = 'ERROR'
            Message     = 'No BOM items found for this request'
            ApiResponse = ''
          )
        ).

      CONTINUE.

    ENDIF.

    DATA(ls_result) = zcl_bom_create_api=>create_bom(
      is_header = VALUE #(
        bom_id     = ls_header-BomId
        material   = ls_header-Material
        plant      = ls_header-Plant
        bom_usage  = ls_header-BomUsage
        alt_bom    = ls_header-AltBom
        base_qty   = ls_header-BaseQty
        base_uom   = ls_header-BaseUom
        valid_from = ls_header-ValidFrom
      )
      it_item = lt_bom_item
    ).

    MODIFY ENTITIES OF ZI_BOM_HDR_N IN LOCAL MODE
      ENTITY ZI_BOM_HDR_N
      UPDATE FIELDS ( Status Message BaseUom ApiResponse )
      WITH VALUE #(
        (
          BomId       = ls_header-BomId
          Status      = ls_result-status
          Message     = ls_result-message
          BaseUom     = ls_result-base_uom
          ApiResponse = ls_result-api_response
        )
      ).

  ENDLOOP.

ENDMETHOD.

METHOD SubmitBOM.

  READ ENTITIES OF ZI_BOM_HDR_N IN LOCAL MODE
    ENTITY ZI_BOM_HDR_N
    ALL FIELDS
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_header).

  READ ENTITIES OF ZI_BOM_HDR_N IN LOCAL MODE
    ENTITY ZI_BOM_HDR_N BY \_Item
    ALL FIELDS
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_item).

  LOOP AT lt_header INTO DATA(ls_header).

    DATA lt_bom_item TYPE zcl_bom_create_api=>ty_item_tab.

    LOOP AT lt_item INTO DATA(ls_item)
      WHERE BomId = ls_header-BomId.

      APPEND VALUE #(
        item_no       = ls_item-ItemNo
        item_category = ls_item-ItemCategory
        component     = ls_item-Component
        quantity      = ls_item-Quantity
        uom           = ls_item-Uom
        item_text     = ls_item-ItemText
      ) TO lt_bom_item.

    ENDLOOP.

    IF lt_bom_item IS INITIAL.

      MODIFY ENTITIES OF ZI_BOM_HDR_N IN LOCAL MODE
        ENTITY ZI_BOM_HDR_N
        UPDATE FIELDS ( Status Message ApiResponse )
        WITH VALUE #(
          (
            BomId       = ls_header-BomId
            Status      = 'ERROR'
            Message     = 'No BOM items found for this request'
            ApiResponse = ''
          )
        ).

      CONTINUE.

    ENDIF.

    DATA(ls_result) = zcl_bom_create_api=>create_bom(
      is_header = VALUE #(
        bom_id     = ls_header-BomId
        material   = ls_header-Material
        plant      = ls_header-Plant
        bom_usage  = ls_header-BomUsage
        alt_bom    = ls_header-AltBom
        base_qty   = ls_header-BaseQty
        base_uom   = ls_header-BaseUom
        valid_from = ls_header-ValidFrom
      )
      it_item = lt_bom_item
    ).

    MODIFY ENTITIES OF ZI_BOM_HDR_N IN LOCAL MODE
      ENTITY ZI_BOM_HDR_N
      UPDATE FIELDS ( Status Message BaseUom ApiResponse )
      WITH VALUE #(
        (
          BomId       = ls_header-BomId
          Status      = ls_result-status
          Message     = ls_result-message
          BaseUom     = ls_result-base_uom
          ApiResponse = ls_result-api_response
        )
      ).

    READ ENTITIES OF ZI_BOM_HDR_N IN LOCAL MODE
      ENTITY ZI_BOM_HDR_N
      ALL FIELDS
      WITH VALUE #( ( BomId = ls_header-BomId ) )
      RESULT DATA(lt_updated).

    IF lt_updated IS NOT INITIAL.
      APPEND VALUE #(
        %tky   = ls_header-%tky
        %param = lt_updated[ 1 ]
      ) TO result.
    ENDIF.

  ENDLOOP.

ENDMETHOD.
ENDCLASS.
