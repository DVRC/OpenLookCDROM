/* (c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
 * Sun design patents pending in the U.S. and foreign countries. 
 * See LEGAL_NOTICE file for terms of the license.
 * 
 * Nearly all XGL operations are defined as macros that side effect
 * their arguments.  The corresponding Lisp functions call one of the 
 * "macro_" functions defined below.
*/


#include <xgl/xgl.h>


macro_xgl_context_pop(ctx)
	Xgl_ctx ctx;

{
  xgl_context_pop(ctx);
}


void
macro_xgl_context_post(ctx, await_flag)
	Xgl_ctx ctx;
	Xgl_boolean await_flag;
{
   xgl_context_post(ctx, await_flag);
}


void
macro_xgl_context_push(ctx, attr_list)
	Xgl_ctx ctx;
	Xgl_attribute attr_list[];
{
  xgl_context_push(ctx, attr_list);
}


void
macro_xgl_pick_clear(ctx)
	Xgl_ctx ctx;
{
  xgl_pick_clear(ctx);
}


void
macro_xgl_pick_get_identifiers(ctx, count, pick_id_list)
	Xgl_ctx ctx;
	Xgl_usgn32 *count;
	Xgl_pick_info pick_id_list[];
{
   xgl_pick_get_identifiers(ctx, count, pick_id_list);
}



void
macro_xgl_stroke_text_extent(ctx, string, rect, cat_pt)
	Xgl_ctx ctx;
	char *string;
	Xgl_bounds_f2d *rect;
	Xgl_pt_f2d *cat_pt;
{
   xgl_stroke_text_extent(ctx, string, rect, cat_pt);
}



void
macro_xgl_light_copy(dest_light, src_light)
	Xgl_light dest_light;
	Xgl_light src_light;
{
   xgl_light_copy(dest_light, src_light);
}


void
macro_xgl_context_copy_raster(dest_ctx, rectangle, position, src_ras)
	Xgl_ctx		dest_ctx;
	Xgl_bounds_i2d	*rectangle;
	Xgl_pt_i2d	*position;
	Xgl_ras		src_ras;
{
   xgl_context_copy_raster(dest_ctx, rectangle, position, src_ras);
}




Xgl_boolean
macro_xgl_context_get_pixel(ctx, position, value)
	Xgl_ctx		ctx;
	Xgl_pt_i2d	*position;
	Xgl_color	*value;
{
   return xgl_context_get_pixel(ctx, position, value);
}


void
macro_xgl_context_new_frame(ctx)
	Xgl_ctx		ctx;
{
   xgl_context_new_frame(ctx);
}



void
macro_xgl_context_set_pixel(ctx, position, value)
	Xgl_ctx ctx;
	Xgl_pt_i2d *position;
	Xgl_color *value;
{
  xgl_context_set_pixel(ctx, position, value);
}



void
macro_xgl_multi_simple_polygon(ctx, flags, facets, bbox, num_pt_lists, pl)
	Xgl_ctx ctx;
	Xgl_facet_flags flags;
	Xgl_facet_list *facets;
	Xgl_bbox *bbox;
	Xgl_usgn32 num_pt_lists;
	Xgl_pt_list pl[];
{
   xgl_multi_simple_polygon(ctx, flags, facets, bbox, num_pt_lists, pl);
}


void
macro_xgl_multiarc(ctx, arc_list)
	Xgl_ctx ctx;
	Xgl_arc_list *arc_list;
{
   xgl_multiarc(ctx, arc_list);
}


void
macro_xgl_multicircle(ctx, circle_list)
	Xgl_ctx ctx;
	Xgl_circle_list *circle_list;
{
   xgl_multicircle(ctx, circle_list);
}


void
macro_xgl_multimarker(ctx, pl)
	Xgl_ctx ctx;
	Xgl_pt_list *pl;
{
   xgl_multimarker(ctx, pl);
}


void
macro_xgl_multipolyline(ctx, bounding_box, num_pt_lists, pl)
	Xgl_ctx ctx;
	Xgl_bbox *bounding_box;
	Xgl_usgn32 num_pt_lists;
	Xgl_pt_list pl[];
{
   xgl_multipolyline(ctx, bounding_box, num_pt_lists, pl);
}



void
macro_xgl_multirectangle(ctx, rect_list)
	Xgl_ctx ctx;
	Xgl_rect_list *rect_list;
{
   xgl_multirectangle(ctx, rect_list);
}



void
macro_xgl_nu_bspline_curve(ctx, curve)
	Xgl_ctx ctx;
	Xgl_nurbs_curve curve;
{
   xgl_nu_bspline_curve(ctx, curve);
}


void
macro_xgl_polygon(ctx, facet_type, facet, bbox, num_pt_lists, pl)
	Xgl_ctx ctx;
	Xgl_facet_type facet_type;
	Xgl_facet *facet;
	Xgl_bbox *bbox;
	Xgl_usgn32 num_pt_lists;
	Xgl_pt_list pl[];
{
   xgl_polygon(ctx, facet_type, facet, bbox, num_pt_lists, pl);
}


/* 
void
macro_xgl_polyhedron(ctx, facets, pts, polyhedron)
	Xgl_ctx ctx;
	Xgl_facet_list *facets;
	Xgl_pt_list *pts;
	Xgl_polyhedron *polyhedron;
{
   xgl_polyhedron(ctx, facets, pts, polyhedron);
}
*/

void
macro_xgl_quadrilateral_mesh(ctx, row_dim, col_dim, facets, pl)
	Xgl_ctx ctx;
	Xgl_usgn32 row_dim, col_dim;
	Xgl_facet_list *facets;
	Xgl_pt_list *pl;
{
   xgl_quadrilateral_mesh(ctx, row_dim, col_dim, facets, pl);
}



void
macro_xgl_stroke_text_2d(ctx, str, pos)
	Xgl_2d_ctx ctx;
	char *str;
	Xgl_pt_f2d *pos;
{
   xgl_stroke_text_2d(ctx, str, pos);
}  


/* 
void
macro_xgl_stroke_text_3d(ctx, str, pos, dir)
	Xgl_3d_ctx ctx;
	char *str;
	Xgl_pt_f3d *pos;
	Xgl_vector3 dir[];
{
   xgl_stroke_text_3d(ctx, str, pos, dir);
}
*/

void
macro_xgl_triangle_strip(ctx, facets, pl)
	Xgl_ctx ctx;
	Xgl_facet_list *facets;
	Xgl_pt_list *pl;
{
   xgl_triangle_strip(ctx, facets, pl);
}


void
macro_xgl_close(system_state)
	Xgl_sys_st	system_state;
{
   xgl_close(system_state);
}



void
macro_xgl_object_destroy(handle)
	Xgl_obj handle;
{
   xgl_object_destroy(handle);
}


void
macro_xgl_object_get(obj, attr, val)
	Xgl_obj obj;
	Xgl_attribute attr;
	void *val;
{
   xgl_object_get(obj, attr, val);
}


void
macro_xgl_transform_copy(dest_trans, src_trans)
	Xgl_trans dest_trans;
	Xgl_trans src_trans;
{
   xgl_transform_copy(dest_trans, src_trans);
}


void
macro_xgl_transform_identity(trans)
	Xgl_trans trans;
{
   xgl_transform_identity(trans);
}


Xgl_trans
macro_xgl_transform_invert(dest_trans, src_trans)
	Xgl_trans dest_trans;
	Xgl_trans src_trans;
{
   return xgl_transform_invert(dest_trans, src_trans);
}


void
macro_xgl_transform_multiply(dest_trans, left_src_trans, right_src_trans)
	Xgl_trans dest_trans,
	left_src_trans,
	right_src_trans;
{
   xgl_transform_multiply(dest_trans, left_src_trans, right_src_trans);
}



void
macro_xgl_transform_point(trans, point)
	Xgl_trans trans;
	Xgl_pt *point;
{
   xgl_transform_point(trans, point);
}


void
macro_xgl_transform_point_list(trans, src_pt_list, dest_pts)
	Xgl_trans trans;
	Xgl_pt_list *src_pt_list;
	void *dest_pts;
{
   xgl_transform_point_list(trans, src_pt_list, dest_pts);
}


void
macro_xgl_transform_read(src_trans, matrix)
	Xgl_trans src_trans;
	void *matrix;
{
   xgl_transform_read(src_trans, matrix);
}


void
macro_xgl_transform_rotate(trans, angle, axis, update)
	Xgl_trans trans;
	float angle;
	Xgl_axis axis;
	Xgl_trans_update update;
{
   xgl_transform_rotate(trans, angle, axis, update);
}


void
macro_xgl_transform_scale(trans, scale_factors, update)
	Xgl_trans trans;
	Xgl_pt *scale_factors;
	Xgl_trans_update update;
{
   xgl_transform_scale(trans, scale_factors, update);
}


void
macro_xgl_transform_translate(trans, offset, update)
	Xgl_trans trans;
	Xgl_pt *offset;
	Xgl_trans_update update;
{
   xgl_transform_translate(trans, offset, update);
}



void
macro_xgl_transform_transpose(dest_trans, src_trans)
	Xgl_trans dest_trans;
	Xgl_trans src_trans;
{
   xgl_transform_transpose(dest_trans, src_trans);
}



void
macro_xgl_transform_write(dest_trans, matrix)
	Xgl_trans dest_trans;
	void *matrix;
{
   xgl_transform_write(dest_trans, matrix);
}


