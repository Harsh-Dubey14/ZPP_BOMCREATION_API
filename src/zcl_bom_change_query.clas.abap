*CLASS zcl_bom_change_query DEFINITION
*  PUBLIC
*  FINAL
*  CREATE PUBLIC.
*
*  PUBLIC SECTION.
*    INTERFACES if_rap_query_provider.
*
*ENDCLASS.
*
*
*CLASS zcl_bom_change_query IMPLEMENTATION.
*
*  METHOD if_rap_query_provider~select.
*
*    DATA lt_result TYPE STANDARD TABLE OF zce_bom_change_read.
*    DATA lt_paged  TYPE STANDARD TABLE OF zce_bom_change_read.
*
*    DATA lv_material TYPE i_billofmaterialitemtp_3-material.
*    DATA lv_plant    TYPE i_billofmaterialitemtp_3-plant.
*    DATA lv_altbom   TYPE i_billofmaterialitemtp_3-billofmaterialvariant.
*    DATA lv_usage    TYPE i_billofmaterialitemtp_3-billofmaterialvariantusage.
*    DATA lv_bom      TYPE i_billofmaterialitemtp_3-billofmaterial.
*
*    DATA ls_header TYPE zce_bom_change_read.
*
*    lv_usage = '1'.
*
*    TRY.
*
*        DATA(lt_filter) = io_request->get_filter( )->get_as_ranges( ).
*
*        LOOP AT lt_filter INTO DATA(ls_filter).
*
*          CASE to_upper( ls_filter-name ).
*
*            WHEN 'MATERIAL'.
*              IF ls_filter-range IS NOT INITIAL.
*                lv_material = ls_filter-range[ 1 ]-low.
*              ENDIF.
*
*            WHEN 'PLANT'.
*              IF ls_filter-range IS NOT INITIAL.
*                lv_plant = ls_filter-range[ 1 ]-low.
*              ENDIF.
*
*            WHEN 'BILLOFMATERIALVARIANT'.
*              IF ls_filter-range IS NOT INITIAL.
*                lv_altbom = ls_filter-range[ 1 ]-low.
*              ENDIF.
*
*            WHEN 'BILLOFMATERIALVARIANTUSAGE'.
*              IF ls_filter-range IS NOT INITIAL.
*                lv_usage = ls_filter-range[ 1 ]-low.
*              ENDIF.
*
*            WHEN 'BILLOFMATERIAL'.
*              IF ls_filter-range IS NOT INITIAL.
*                lv_bom = ls_filter-range[ 1 ]-low.
*              ENDIF.
*
*          ENDCASE.
*
*        ENDLOOP.
*
*        CONDENSE:
*          lv_material NO-GAPS,
*          lv_plant    NO-GAPS,
*          lv_altbom   NO-GAPS,
*          lv_usage    NO-GAPS,
*          lv_bom      NO-GAPS.
*
*        " Normalize Alternative BOM
*        " Example: 2 -> 02
*        IF lv_altbom IS NOT INITIAL AND strlen( lv_altbom ) = 1.
*          lv_altbom = |0{ lv_altbom }|.
*        ENDIF.
*
*        " Normalize BOM Number
*        " Example: 125 -> 00000125
*        IF lv_bom IS NOT INITIAL AND strlen( lv_bom ) < 8.
*          lv_bom = |{ lv_bom WIDTH = 8 ALIGN = RIGHT PAD = '0' }|.
*        ENDIF.
*
*        IF lv_usage IS INITIAL.
*          lv_usage = '1'.
*        ENDIF.
*
*        IF lv_altbom IS INITIAL.
*
*          APPEND VALUE #(
*            bomkey  = cl_system_uuid=>create_uuid_c32_static( )
*            status  = 'ERROR'
*            message = 'Alternative BOM is mandatory'
*          ) TO lt_result.
*
*        ELSEIF lv_bom IS INITIAL
*           AND ( lv_material IS INITIAL OR lv_plant IS INITIAL ).
*
*          APPEND VALUE #(
*            bomkey  = cl_system_uuid=>create_uuid_c32_static( )
*            status  = 'ERROR'
*            message = 'Either BOM Number or Material + Plant is mandatory'
*          ) TO lt_result.
*
*        ELSE.
*
*          IF lv_bom IS NOT INITIAL.
*
*            SELECT
*              FROM i_billofmaterialitemtp_3 WITH PRIVILEGED ACCESS
*              FIELDS
*                billofmaterial,
*                billofmaterialcategory,
*                billofmaterialvariant,
*                billofmaterialvariantusage,
*                billofmaterialversion,
*                headerchangedocument,
*                material,
*                bomitemsorter,
*                plant,
*                billofmaterialitemnodenumber,
*                billofmaterialitemnumber,
*                billofmaterialitemcategory,
*                billofmaterialcomponent,
*                billofmaterialitemquantity,
*                billofmaterialitemunit
*              WHERE billofmaterial             = @lv_bom
*                AND billofmaterialvariant      = @lv_altbom
*                AND billofmaterialvariantusage = @lv_usage
*                AND billofmaterialcategory     = 'M'
*              INTO TABLE @DATA(lt_items).
*
*          ELSE.
*
*            SELECT
*              FROM i_billofmaterialitemtp_3 WITH PRIVILEGED ACCESS
*              FIELDS
*                billofmaterial,
*                billofmaterialcategory,
*                billofmaterialvariant,
*                billofmaterialvariantusage,
*                billofmaterialversion,
*                headerchangedocument,
*                material,
*                bomitemsorter,
*                plant,
*                billofmaterialitemnodenumber,
*                billofmaterialitemnumber,
*                billofmaterialitemcategory,
*                billofmaterialcomponent,
*                billofmaterialitemquantity,
*                billofmaterialitemunit
*              WHERE material                   = @lv_material
*                AND plant                      = @lv_plant
*                AND billofmaterialvariant      = @lv_altbom
*                AND billofmaterialvariantusage = @lv_usage
*                AND billofmaterialcategory     = 'M'
*              INTO TABLE @lt_items.
*
*          ENDIF.
*
*          IF lt_items IS INITIAL.
*
*            APPEND VALUE #(
*              bomkey                     = cl_system_uuid=>create_uuid_c32_static( )
*              billofmaterialvariant      = lv_altbom
*              billofmaterialvariantusage = lv_usage
*              material                   = lv_material
*              plant                      = lv_plant
*              rowstatus                  = 'ERROR'
*              isnew                      = abap_false
*              ischanged                  = abap_false
*              status                     = 'ERROR'
*              message                    = 'No BOM found for given input'
*            ) TO lt_result.
*
*          ELSE.
*
*            CLEAR ls_header.
*
*            DATA(ls_first_item) = lt_items[ 1 ].
*
*            SELECT SINGLE
*              FROM i_billofmaterialtp_2 WITH PRIVILEGED ACCESS
*              FIELDS
*                billofmaterial,
*                billofmaterialcategory,
*                billofmaterialvariant,
*                billofmaterialvariantusage,
*                billofmaterialversion,
*                material,
*                plant,
*                bomheaderquantityinbaseunit,
*                bomheaderbaseunit,
*                headervaliditystartdate,
*                bomversionstatus
*              WHERE billofmaterial             = @ls_first_item-billofmaterial
*                AND billofmaterialcategory     = @ls_first_item-billofmaterialcategory
*                AND billofmaterialvariant      = @ls_first_item-billofmaterialvariant
*                AND billofmaterialvariantusage = @ls_first_item-billofmaterialvariantusage
*              INTO @DATA(ls_bom_header).
*
*            IF sy-subrc = 0.
*
*              ls_header-billofmaterial              = ls_bom_header-billofmaterial.
*              ls_header-billofmaterialcategory      = ls_bom_header-billofmaterialcategory.
*              ls_header-billofmaterialvariant       = ls_bom_header-billofmaterialvariant.
*              ls_header-billofmaterialvariantusage  = ls_bom_header-billofmaterialvariantusage.
*              ls_header-billofmaterialversion       = ls_bom_header-billofmaterialversion.
*              ls_header-material                    = ls_bom_header-material.
*              ls_header-plant                       = ls_bom_header-plant.
*              ls_header-bomheaderquantityinbaseunit = ls_bom_header-bomheaderquantityinbaseunit.
*              ls_header-bomheaderbaseunit           = ls_bom_header-bomheaderbaseunit.
*              ls_header-headervaliditystartdate     = ls_bom_header-headervaliditystartdate.
*              ls_header-bomversionstatus            = ls_bom_header-bomversionstatus.
*
*            ENDIF.
*
*            LOOP AT lt_items INTO DATA(ls_item).
*
*              APPEND VALUE #(
*                bomkey = |{ ls_item-billofmaterial }_{ ls_item-billofmaterialvariant }_{ ls_item-billofmaterialitemnodenumber }|
*
*                billofmaterial             = ls_item-billofmaterial
*                billofmaterialcategory     = ls_item-billofmaterialcategory
*                billofmaterialvariant      = ls_item-billofmaterialvariant
*                billofmaterialvariantusage = ls_item-billofmaterialvariantusage
*
*                billofmaterialversion = COND #(
*                  WHEN ls_header-billofmaterialversion IS NOT INITIAL
*                  THEN ls_header-billofmaterialversion
*                  ELSE ls_item-billofmaterialversion )
*
*                headerchangedocument = ls_item-headerchangedocument
*
*                material = COND #(
*                  WHEN ls_header-material IS NOT INITIAL
*                  THEN ls_header-material
*                  ELSE ls_item-material )
*
*                plant = COND #(
*                  WHEN ls_header-plant IS NOT INITIAL
*                  THEN ls_header-plant
*                  ELSE ls_item-plant )
*
*                bomheaderquantityinbaseunit = ls_header-bomheaderquantityinbaseunit
*                bomheaderbaseunit           = ls_header-bomheaderbaseunit
*                headervaliditystartdate     = ls_header-headervaliditystartdate
*                bomversionstatus            = ls_header-bomversionstatus
*
*                billofmaterialitemnodenumber = ls_item-billofmaterialitemnodenumber
*                billofmaterialitemnumber     = ls_item-billofmaterialitemnumber
*                billofmaterialitemcategory   = ls_item-billofmaterialitemcategory
*                billofmaterialcomponent      = ls_item-billofmaterialcomponent
*                billofmaterialitemquantity   = ls_item-billofmaterialitemquantity
*                billofmaterialitemunit       = ls_item-billofmaterialitemunit
*
*                bomitemdescription   = ''
*                bomitemsorter        = ls_item-bomitemsorter
*                isproductionrelevant = abap_true
*
*                rowstatus = 'EXISTING'
*                isnew     = abap_false
*                ischanged = abap_false
*
*                status  = 'SUCCESS'
*                message = 'BOM item fetched successfully'
*              ) TO lt_result.
*
*            ENDLOOP.
*
*          ENDIF.
*
*        ENDIF.
*
*      CATCH cx_root INTO DATA(lx_error).
*
*        CLEAR lt_result.
*
*        APPEND VALUE #(
*          bomkey    = cl_system_uuid=>create_uuid_c32_static( )
*          rowstatus = 'ERROR'
*          isnew     = abap_false
*          ischanged = abap_false
*          status    = 'ERROR'
*          message   = lx_error->get_text( )
*        ) TO lt_result.
*
*    ENDTRY.
*
*    DATA(lv_top)  = io_request->get_paging( )->get_page_size( ).
*    DATA(lv_skip) = io_request->get_paging( )->get_offset( ).
*
*    IF lv_top < 0.
*      lv_top = lines( lt_result ).
*    ENDIF.
*
*    DATA(lv_index) = 0.
*
*    LOOP AT lt_result INTO DATA(ls_result).
*
*      lv_index += 1.
*
*      IF lv_index > lv_skip AND lv_index <= lv_skip + lv_top.
*        APPEND ls_result TO lt_paged.
*      ENDIF.
*
*    ENDLOOP.
*
*    IF io_request->is_data_requested( ).
*      io_response->set_data( lt_paged ).
*    ENDIF.
*
*    IF io_request->is_total_numb_of_rec_requested( ).
*      io_response->set_total_number_of_records(
*        CONV int8( lines( lt_result ) )
*      ).
*    ENDIF.
*
*  ENDMETHOD.
*
*ENDCLASS.



CLASS zcl_bom_change_query DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.

ENDCLASS.


CLASS zcl_bom_change_query IMPLEMENTATION.

  METHOD if_rap_query_provider~select.

    DATA lt_result TYPE STANDARD TABLE OF zce_bom_change_read.
    DATA lt_paged  TYPE STANDARD TABLE OF zce_bom_change_read.

    DATA lv_material TYPE i_billofmaterialitemtp_3-material.
    DATA lv_plant    TYPE i_billofmaterialitemtp_3-plant.
    DATA lv_altbom   TYPE i_billofmaterialitemtp_3-billofmaterialvariant.
    DATA lv_usage    TYPE i_billofmaterialitemtp_3-billofmaterialvariantusage.
    DATA lv_bom      TYPE i_billofmaterialitemtp_3-billofmaterial.

    DATA ls_header TYPE zce_bom_change_read.

    lv_usage = '1'.

    TRY.

        DATA(lt_filter) = io_request->get_filter( )->get_as_ranges( ).

        LOOP AT lt_filter INTO DATA(ls_filter).

          CASE to_upper( ls_filter-name ).

            WHEN 'MATERIAL'.
              IF ls_filter-range IS NOT INITIAL.
                lv_material = ls_filter-range[ 1 ]-low.
              ENDIF.

            WHEN 'PLANT'.
              IF ls_filter-range IS NOT INITIAL.
                lv_plant = ls_filter-range[ 1 ]-low.
              ENDIF.

            WHEN 'BILLOFMATERIALVARIANT'.
              IF ls_filter-range IS NOT INITIAL.
                lv_altbom = ls_filter-range[ 1 ]-low.
              ENDIF.

            WHEN 'BILLOFMATERIALVARIANTUSAGE'.
              IF ls_filter-range IS NOT INITIAL.
                lv_usage = ls_filter-range[ 1 ]-low.
              ENDIF.

            WHEN 'BILLOFMATERIAL'.
              IF ls_filter-range IS NOT INITIAL.
                lv_bom = ls_filter-range[ 1 ]-low.
              ENDIF.

          ENDCASE.

        ENDLOOP.

        CONDENSE:
          lv_material NO-GAPS,
          lv_plant    NO-GAPS,
          lv_altbom   NO-GAPS,
          lv_usage    NO-GAPS,
          lv_bom      NO-GAPS.

        " Normalize Alternative BOM
        " Example: 2 -> 02
        IF lv_altbom IS NOT INITIAL AND strlen( lv_altbom ) = 1.
          lv_altbom = |0{ lv_altbom }|.
        ENDIF.

        " Normalize BOM Number
        " Example: 125 -> 00000125
        IF lv_bom IS NOT INITIAL AND strlen( lv_bom ) < 8.
          lv_bom = |{ lv_bom WIDTH = 8 ALIGN = RIGHT PAD = '0' }|.
        ENDIF.

        IF lv_usage IS INITIAL.
          lv_usage = '1'.
        ENDIF.

        IF lv_altbom IS INITIAL.

          APPEND VALUE #(
            bomkey  = cl_system_uuid=>create_uuid_c32_static( )
            status  = 'ERROR'
            message = 'Alternative BOM is mandatory'
          ) TO lt_result.

        ELSEIF lv_bom IS INITIAL
           AND ( lv_material IS INITIAL OR lv_plant IS INITIAL ).

          APPEND VALUE #(
            bomkey  = cl_system_uuid=>create_uuid_c32_static( )
            status  = 'ERROR'
            message = 'Either BOM Number or Material + Plant is mandatory'
          ) TO lt_result.

        ELSE.

          IF lv_bom IS NOT INITIAL.

            SELECT
              FROM i_billofmaterialitemtp_3 WITH PRIVILEGED ACCESS
              FIELDS
                billofmaterial,
                billofmaterialcategory,
                billofmaterialvariant,
                billofmaterialvariantusage,
                billofmaterialversion,
                headerchangedocument,
                material,
                bomitemsorter,
                plant,
                billofmaterialitemnodenumber,
                billofmaterialitemnumber,
                billofmaterialitemcategory,
                billofmaterialcomponent,
                billofmaterialitemquantity,
                billofmaterialitemunit
              WHERE billofmaterial             = @lv_bom
                AND billofmaterialvariant      = @lv_altbom
                AND billofmaterialvariantusage = @lv_usage
                AND billofmaterialcategory     = 'M'
              INTO TABLE @DATA(lt_items).

          ELSE.

            SELECT
              FROM i_billofmaterialitemtp_3 WITH PRIVILEGED ACCESS
              FIELDS
                billofmaterial,
                billofmaterialcategory,
                billofmaterialvariant,
                billofmaterialvariantusage,
                billofmaterialversion,
                headerchangedocument,
                material,
                bomitemsorter,
                plant,
                billofmaterialitemnodenumber,
                billofmaterialitemnumber,
                billofmaterialitemcategory,
                billofmaterialcomponent,
                billofmaterialitemquantity,
                billofmaterialitemunit
              WHERE material                   = @lv_material
                AND plant                      = @lv_plant
                AND billofmaterialvariant      = @lv_altbom
                AND billofmaterialvariantusage = @lv_usage
                AND billofmaterialcategory     = 'M'
              INTO TABLE @lt_items.

          ENDIF.

          IF lt_items IS INITIAL.

            APPEND VALUE #(
              bomkey                     = cl_system_uuid=>create_uuid_c32_static( )
              billofmaterialvariant      = lv_altbom
              billofmaterialvariantusage = lv_usage
              material                   = lv_material
              plant                      = lv_plant
              rowstatus                  = 'ERROR'
              isnew                      = abap_false
              ischanged                  = abap_false
              status                     = 'ERROR'
              message                    = 'No BOM found for given input'
            ) TO lt_result.

          ELSE.

            CLEAR ls_header.

            DATA(ls_first_item) = lt_items[ 1 ].

            SELECT SINGLE
              FROM i_billofmaterialtp_2 WITH PRIVILEGED ACCESS
              FIELDS
                billofmaterial,
                billofmaterialcategory,
                billofmaterialvariant,
                billofmaterialvariantusage,
                billofmaterialversion,
                material,
                plant,
                bomheaderquantityinbaseunit,
                bomheaderbaseunit,
                headervaliditystartdate,
                bomversionstatus
              WHERE billofmaterial             = @ls_first_item-billofmaterial
                AND billofmaterialcategory     = @ls_first_item-billofmaterialcategory
                AND billofmaterialvariant      = @ls_first_item-billofmaterialvariant
                AND billofmaterialvariantusage = @ls_first_item-billofmaterialvariantusage
              INTO @DATA(ls_bom_header).

            IF sy-subrc = 0.

              DATA lv_header_uom TYPE meins.

              lv_header_uom = zcl_uom_nzr_helper=>normalize_uom(
                                CONV meins( ls_bom_header-bomheaderbaseunit )
                              ).

              CONDENSE lv_header_uom NO-GAPS.
              TRANSLATE lv_header_uom TO UPPER CASE.

              ls_header-billofmaterial              = ls_bom_header-billofmaterial.
              ls_header-billofmaterialcategory      = ls_bom_header-billofmaterialcategory.
              ls_header-billofmaterialvariant       = ls_bom_header-billofmaterialvariant.
              ls_header-billofmaterialvariantusage  = ls_bom_header-billofmaterialvariantusage.
              ls_header-billofmaterialversion       = ls_bom_header-billofmaterialversion.
              ls_header-material                    = ls_bom_header-material.
              ls_header-plant                       = ls_bom_header-plant.
              ls_header-bomheaderquantityinbaseunit = ls_bom_header-bomheaderquantityinbaseunit.
              ls_header-bomheaderbaseunit           = lv_header_uom.
              ls_header-headervaliditystartdate     = ls_bom_header-headervaliditystartdate.
              ls_header-bomversionstatus            = ls_bom_header-bomversionstatus.

            ENDIF.

            LOOP AT lt_items INTO DATA(ls_item).

              DATA lv_item_uom TYPE meins.

              lv_item_uom = zcl_uom_nzr_helper=>normalize_uom(
                              CONV meins( ls_item-billofmaterialitemunit )
                            ).

              CONDENSE lv_item_uom NO-GAPS.
              TRANSLATE lv_item_uom TO UPPER CASE.

              APPEND VALUE #(
                bomkey = |{ ls_item-billofmaterial }_{ ls_item-billofmaterialvariant }_{ ls_item-billofmaterialitemnodenumber }|

                billofmaterial             = ls_item-billofmaterial
                billofmaterialcategory     = ls_item-billofmaterialcategory
                billofmaterialvariant      = ls_item-billofmaterialvariant
                billofmaterialvariantusage = ls_item-billofmaterialvariantusage

                billofmaterialversion = COND #(
                  WHEN ls_header-billofmaterialversion IS NOT INITIAL
                  THEN ls_header-billofmaterialversion
                  ELSE ls_item-billofmaterialversion )

                headerchangedocument = ls_item-headerchangedocument

                material = COND #(
                  WHEN ls_header-material IS NOT INITIAL
                  THEN ls_header-material
                  ELSE ls_item-material )

                plant = COND #(
                  WHEN ls_header-plant IS NOT INITIAL
                  THEN ls_header-plant
                  ELSE ls_item-plant )

                bomheaderquantityinbaseunit = ls_header-bomheaderquantityinbaseunit
                bomheaderbaseunit           = ls_header-bomheaderbaseunit
                headervaliditystartdate     = ls_header-headervaliditystartdate
                bomversionstatus            = ls_header-bomversionstatus

                billofmaterialitemnodenumber = ls_item-billofmaterialitemnodenumber
                billofmaterialitemnumber     = ls_item-billofmaterialitemnumber
                billofmaterialitemcategory   = ls_item-billofmaterialitemcategory
                billofmaterialcomponent      = ls_item-billofmaterialcomponent
                billofmaterialitemquantity   = ls_item-billofmaterialitemquantity
                billofmaterialitemunit       = lv_item_uom

                bomitemdescription   = ''
                bomitemsorter        = ls_item-bomitemsorter
                isproductionrelevant = abap_true

                rowstatus = 'EXISTING'
                isnew     = abap_false
                ischanged = abap_false

                status  = 'SUCCESS'
                message = 'BOM item fetched successfully'
              ) TO lt_result.

            ENDLOOP.

          ENDIF.

        ENDIF.

      CATCH cx_root INTO DATA(lx_error).

        CLEAR lt_result.

        APPEND VALUE #(
          bomkey    = cl_system_uuid=>create_uuid_c32_static( )
          rowstatus = 'ERROR'
          isnew     = abap_false
          ischanged = abap_false
          status    = 'ERROR'
          message   = lx_error->get_text( )
        ) TO lt_result.

    ENDTRY.

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
