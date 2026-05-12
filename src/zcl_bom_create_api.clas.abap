CLASS zcl_bom_create_api DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES: BEGIN OF ty_header,
             bom_id       TYPE sysuuid_x16,
             material     TYPE matnr,
             plant        TYPE werks_d,
             bom_usage(1) TYPE c,
             alt_bom(2)   TYPE c,
             base_qty     TYPE p LENGTH 16 DECIMALS 3,
             base_uom     TYPE meins,
             valid_from   TYPE d,
           END OF ty_header.

    TYPES: BEGIN OF ty_item,
             item_no(4)       TYPE c,
             item_category(1) TYPE c,
             component        TYPE matnr,
             quantity         TYPE p LENGTH 16 DECIMALS 3,
             uom              TYPE meins,
             item_text(40)    TYPE c,
           END OF ty_item.

    TYPES ty_item_tab TYPE STANDARD TABLE OF ty_item WITH EMPTY KEY.

    TYPES: BEGIN OF ty_result,
             success      TYPE abap_boolean,
             base_uom     TYPE meins,
             status(20)   TYPE c,
             message(255) TYPE c,
             api_response TYPE string,
           END OF ty_result.

    CLASS-METHODS create_bom
      IMPORTING
        is_header        TYPE ty_header
        it_item          TYPE ty_item_tab
      RETURNING
        VALUE(rs_result) TYPE ty_result.

  PRIVATE SECTION.

    CONSTANTS lc_bom_api_path TYPE string
      VALUE '/sap/opu/odata/sap/API_BILL_OF_MATERIAL_SRV;v=0002/MaterialBOM'.

    CLASS-METHODS get_base_unit
      IMPORTING
        iv_material        TYPE matnr
      RETURNING
        VALUE(rv_base_uom) TYPE meins.

    CLASS-METHODS build_payload
      IMPORTING
        is_header      TYPE ty_header
        it_item        TYPE ty_item_tab
        iv_base_uom    TYPE meins
      RETURNING
        VALUE(rv_json) TYPE string.

    CLASS-METHODS convert_date_to_odata
      IMPORTING
        iv_date              TYPE d
      RETURNING
        VALUE(rv_odata_date) TYPE string.

    CLASS-METHODS post_to_standard_api
      IMPORTING
        iv_payload       TYPE string
      RETURNING
        VALUE(rs_result) TYPE ty_result.

    CLASS-METHODS get_api_base_url
      RETURNING
        VALUE(rv_url) TYPE string.

    CLASS-METHODS get_basic_auth_header
      RETURNING
        VALUE(rv_authorization) TYPE string.

ENDCLASS.



CLASS zcl_bom_create_api IMPLEMENTATION.

  METHOD create_bom.

    IF is_header-material IS INITIAL.
      rs_result-success = abap_false.
      rs_result-status  = 'ERROR'.
      rs_result-message = 'Material is mandatory'.
      RETURN.
    ENDIF.

    IF is_header-plant IS INITIAL.
      rs_result-success = abap_false.
      rs_result-status  = 'ERROR'.
      rs_result-message = 'Plant is mandatory'.
      RETURN.
    ENDIF.

    IF is_header-alt_bom IS INITIAL.
      rs_result-success = abap_false.
      rs_result-status  = 'ERROR'.
      rs_result-message = 'Alternative BOM / BOM Variant is mandatory'.
      RETURN.
    ENDIF.

    IF it_item IS INITIAL.
      rs_result-success = abap_false.
      rs_result-status  = 'ERROR'.
      rs_result-message = 'At least one BOM item is required'.
      RETURN.
    ENDIF.

    DATA(lv_base_uom) = get_base_unit( is_header-material ).

    IF lv_base_uom IS INITIAL.
      rs_result-success = abap_false.
      rs_result-status  = 'ERROR'.
      rs_result-message = |Base unit not found for material { is_header-material }|.
      RETURN.
    ENDIF.

    DATA(lv_payload) = build_payload(
      is_header   = is_header
      it_item     = it_item
      iv_base_uom = lv_base_uom
    ).

    IF lv_payload IS INITIAL.
      rs_result-success = abap_false.
      rs_result-status  = 'ERROR'.
      rs_result-message = 'Payload could not be built'.
      RETURN.
    ENDIF.

    rs_result = post_to_standard_api( lv_payload ).

    rs_result-base_uom = lv_base_uom.

    IF rs_result-api_response IS INITIAL.
      rs_result-api_response = lv_payload.
    ENDIF.

  ENDMETHOD.



  METHOD get_base_unit.

    SELECT SINGLE BaseUnit
      FROM I_Product WITH PRIVILEGED ACCESS
      WHERE Product = @iv_material
      INTO @rv_base_uom.

  ENDMETHOD.



  METHOD build_payload.

    DATA lv_date TYPE d.

    lv_date = COND #(
      WHEN is_header-valid_from IS INITIAL
      THEN cl_abap_context_info=>get_system_date( )
      ELSE is_header-valid_from
    ).

    DATA(lv_valid_from) = convert_date_to_odata( lv_date ).

    DATA(lv_usage) = COND string(
      WHEN is_header-bom_usage IS INITIAL THEN '1'
      ELSE is_header-bom_usage
    ).

    DATA(lv_alt_bom) = CONV string( is_header-alt_bom ).
    CONDENSE lv_alt_bom NO-GAPS.

    DATA(lv_material) = |{ is_header-material ALPHA = OUT }|.
    CONDENSE lv_material NO-GAPS.

    DATA(lv_plant) = CONV string( is_header-plant ).
    CONDENSE lv_plant NO-GAPS.

    DATA(lv_base_uom) = CONV string( iv_base_uom ).
    CONDENSE lv_base_uom NO-GAPS.

    DATA(lv_items_json) = ``.

    LOOP AT it_item INTO DATA(ls_item).

      DATA(lv_component) = |{ ls_item-component ALPHA = OUT }|.
      CONDENSE lv_component NO-GAPS.

      DATA(lv_item_category) = COND string(
        WHEN ls_item-item_category IS INITIAL THEN 'L'
        ELSE ls_item-item_category
      ).
      CONDENSE lv_item_category NO-GAPS.

      DATA(lv_qty) = |{ ls_item-quantity }|.
      CONDENSE lv_qty NO-GAPS.

      DATA(lv_item_no) = CONV string( ls_item-item_no ).
      CONDENSE lv_item_no NO-GAPS.

      DATA(lv_uom) = CONV string( ls_item-uom ).
      CONDENSE lv_uom NO-GAPS.

      DATA(lv_item_json) =
        `{` &&
        `"BillOfMaterialItemCategory":"` && lv_item_category && `",` &&
        `"BillOfMaterialComponent":"` && lv_component && `",` &&
        `"BillOfMaterialItemQuantity":"` && lv_qty && `",` &&
        `"BillOfMaterialItemUnit":"` && lv_uom && `",` &&
        `"BillOfMaterialItemNumber":"` && lv_item_no && `",` &&
        `"IsProductionRelevant":true` &&
        `}`.

      IF lv_items_json IS INITIAL.
        lv_items_json = lv_item_json.
      ELSE.
        lv_items_json = lv_items_json && `,` && lv_item_json.
      ENDIF.

    ENDLOOP.

    rv_json =
      `{` &&
      `"BillOfMaterialCategory":"M",` &&
      `"BillOfMaterialVariant":"` && lv_alt_bom && `",` &&
      `"Material":"` && lv_material && `",` &&
      `"Plant":"` && lv_plant && `",` &&
      `"BillOfMaterialVariantUsage":"` && lv_usage && `",` &&
      `"BOMHeaderBaseUnit":"` && lv_base_uom && `",` &&
      `"BOMHeaderQuantityInBaseUnit":"1",` &&
      `"HeaderValidityStartDate":"` && lv_valid_from && `",` &&
      `"to_BillOfMaterialItem":{` &&
        `"results":[` && lv_items_json && `]` &&
      `}` &&
      `}`.

  ENDMETHOD.



  METHOD convert_date_to_odata.

    DATA lv_timestamp TYPE timestampl.

    CONVERT DATE iv_date TIME '000000'
      INTO TIME STAMP lv_timestamp
      TIME ZONE 'UTC'.

    DATA(lv_seconds) = cl_abap_tstmp=>subtract(
      tstmp1 = lv_timestamp
      tstmp2 = CONV timestampl( '19700101000000' )
    ).

    DATA(lv_milliseconds) = lv_seconds * 1000.

    rv_odata_date = |/Date({ lv_milliseconds })/|.

  ENDMETHOD.



  METHOD get_api_base_url.

    "Only host here. Full OData path is set in set_uri_path( ).
    rv_url = 'https://my433482-api.s4hana.cloud.sap'.

  ENDMETHOD.



  METHOD get_basic_auth_header.

    DATA lv_username TYPE string VALUE 'VIKRAM_API'.
    DATA lv_password TYPE string VALUE '>z{2B%bvBB)3y+<9Xk652v}$q[SyyF]Y@pr%-Gc2'.
    DATA lv_raw      TYPE string.
    DATA lv_base64   TYPE string.

    lv_raw = |{ lv_username }:{ lv_password }|.

    lv_base64 = cl_web_http_utility=>encode_base64(
      unencoded = lv_raw
    ).

    rv_authorization = |Basic { lv_base64 }|.

  ENDMETHOD.



  METHOD post_to_standard_api.

    DATA lv_base_url      TYPE string.
    DATA lv_authorization TYPE string.
    DATA lv_token         TYPE string.
    DATA lv_response      TYPE string.
    DATA lv_status        TYPE i.

    TRY.

        lv_base_url      = get_api_base_url( ).
        lv_authorization = get_basic_auth_header( ).

        DATA(lo_destination) =
          cl_http_destination_provider=>create_by_url(
            i_url = lv_base_url
          ).

        DATA(lo_client) =
          cl_web_http_client_manager=>create_by_http_destination(
            i_destination = lo_destination
          ).

        "------------------------------------------------------------
        " 1. Fetch CSRF token
        "------------------------------------------------------------
        DATA(lo_request) = lo_client->get_http_request( ).

        lo_request->set_uri_path( lc_bom_api_path ).

        lo_request->set_header_fields( VALUE #(
          ( name = 'Accept'        value = 'application/json' )
          ( name = 'Authorization' value = lv_authorization )
          ( name = 'x-csrf-token'  value = 'Fetch' )
        ) ).

        DATA(lo_response) = lo_client->execute(
          i_method = if_web_http_client=>get
        ).

        lv_status = lo_response->get_status( )-code.

        IF lv_status < 200 OR lv_status >= 300.

          lv_response = lo_response->get_text( ).

          rs_result-success      = abap_false.
          rs_result-status       = 'ERROR'.
          rs_result-message      = |CSRF token fetch failed. HTTP status: { lv_status }|.
          rs_result-api_response = lv_response.
          RETURN.

        ENDIF.

        lv_token = lo_response->get_header_field( 'x-csrf-token' ).

        IF lv_token IS INITIAL.

          lv_response = lo_response->get_text( ).

          rs_result-success      = abap_false.
          rs_result-status       = 'ERROR'.
          rs_result-message      = 'CSRF token not received from BOM API'.
          rs_result-api_response = lv_response.
          RETURN.

        ENDIF.

        "------------------------------------------------------------
        " 2. POST BOM payload
        "------------------------------------------------------------
        lo_request = lo_client->get_http_request( ).

        lo_request->set_uri_path( lc_bom_api_path ).

        lo_request->set_header_fields( VALUE #(
          ( name = 'Accept'        value = 'application/json' )
          ( name = 'Content-Type'  value = 'application/json' )
          ( name = 'Authorization' value = lv_authorization )
          ( name = 'x-csrf-token'  value = lv_token )
        ) ).

        lo_request->set_text( iv_payload ).

        lo_response = lo_client->execute(
          i_method = if_web_http_client=>post
        ).

        lv_status   = lo_response->get_status( )-code.
        lv_response = lo_response->get_text( ).

        IF lv_status >= 200 AND lv_status < 300.

          rs_result-success      = abap_true.
          rs_result-status       = 'SUCCESS'.
          rs_result-message      = |BOM created successfully. HTTP status: { lv_status }|.
          rs_result-api_response = lv_response.

        ELSE.

          rs_result-success      = abap_false.
          rs_result-status       = 'ERROR'.
          rs_result-message      = |BOM creation failed. HTTP status: { lv_status }|.
          rs_result-api_response = lv_response.

        ENDIF.

      CATCH cx_root INTO DATA(lx_error).

        rs_result-success      = abap_false.
        rs_result-status       = 'ERROR'.
        rs_result-message      = lx_error->get_text( ).
        rs_result-api_response = iv_payload.

    ENDTRY.

  ENDMETHOD.

ENDCLASS.
