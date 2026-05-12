CLASS zcl_bom_api_query DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.

ENDCLASS.


CLASS zcl_bom_api_query IMPLEMENTATION.

  METHOD if_rap_query_provider~select.

    DATA lt_result TYPE STANDARD TABLE OF zce_bom_api.
    DATA lt_paged  TYPE STANDARD TABLE OF zce_bom_api.

    APPEND VALUE #(
      ApiId    = 'BOMAPI'
      Material = ''
      Plant    = ''
      Message  = 'BOM Automation API is active'
    ) TO lt_result.

    DATA(lv_top)  = io_request->get_paging( )->get_page_size( ).
    DATA(lv_skip) = io_request->get_paging( )->get_offset( ).

    IF lv_top < 0.
      lv_top = lines( lt_result ).
    ENDIF.

    DATA(lv_index) = 0.

    LOOP AT lt_result INTO DATA(ls_result).
      lv_index += 1.

      IF lv_index > lv_skip AND lv_index <= lv_skip + lv_top.
        APPEND ls_result TO lt_paged.
      ENDIF.
    ENDLOOP.

    IF io_request->is_data_requested( ).
      io_response->set_data( lt_paged ).
    ENDIF.

    IF io_request->is_total_numb_of_rec_requested( ).
      io_response->set_total_number_of_records(
        CONV int8( lines( lt_result ) )
      ).
    ENDIF.

  ENDMETHOD.

ENDCLASS.
