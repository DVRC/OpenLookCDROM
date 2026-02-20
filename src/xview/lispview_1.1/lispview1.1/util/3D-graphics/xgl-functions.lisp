;;;	(c) Copyright 1989, 1990, 1991 Sun Microsystems, Inc. 
;;;	Sun design patents pending in the U.S. and foreign countries. 
;;;	See LEGAL_NOTICE file for terms of the license.


;;;%W% %G%


(in-package "XGL" :use '("LISP" "FOREIGN-FUNCTION-INTERFACE"))

(defmacro def-xgl-function (&rest args)
  `(def-exported-foreign-function ,@args))


(defmacro def-xgl-macro-function (&rest args)
  `(def-exported-foreign-macro ,@args))



(def-xgl-function (XGL-OBJECT-CREATE 
		   (:return-type xgl-object) 
		   (:name "_xgl_object_create")
		   (:max-rest-args 512))
    "General xgl object creation function."
  (state xgl-sys-state)
  (type xgl-obj-type)
  (obj-desc (:pointer xgl-obj-desc))
  &rest attributes)


(def-xgl-function (XGL-COLOR-MAP-CREATE 
		   (:return-type xgl-cmap) 
		   (:name "_xgl_color_map_create")
		   (:max-rest-args 512))
	"xgl_color_map_create creates a color  map  object  and  sets initial  values
	of the specified attributes(those Color Map attributes not specified as
	parameters to the  create  func- tion  will  be initialized to default
	values).  An XGL Color Map object provides the facility to convert colors
	from  one color type to another."
   &rest attributes)


(def-xgl-function (XGL-2D-CONTEXT-CREATE 
		   (:return-type xgl-2d-ctx) 
		   (:name "_xgl_2d_context_create")
		   (:max-rest-args 512))
	"Same as xgl_3d_context_create"
   &rest attributes)


(def-xgl-function (XGL-3D-CONTEXT-CREATE 
		   (:return-type xgl-3d-ctx) 
		   (:name "_xgl_3d_context_create")
		   (:max-rest-args 512))
	"Creates a new 2d or 3d Context and sets initial values of the specified
	attributes. At creation time, a Context is not associated with any Device.
	This has to be explicitly done by the application by setting the
	XGL_CTX_DEVICE(3) attribute in the Context."
   &rest attributes)


(def-xgl-macro-function (XGL-CONTEXT-POP (:return-type :null) (:name "_xgl_context_pop"))
	"The operator xgl_context_pop restores the most recent context state pushed
	onto the internal state stack of context ctx. All the attributes pushed by
	the most recent call to the xgl_context_push operator are restored in the
	context."
   (ctx xgl-ctx))


(def-xgl-macro-function (XGL-CONTEXT-POST (:return-type :null) (:name "_xgl_context_post"))
	"This operator causes any pending graphics primitives for the given context
	to be posted. Some devices can buffer XGL commands and require explicit
	posting to update the screen.  So, return from any XGL function call does
	not necessarily indicate that all actions have been completed."
   (ctx xgl-ctx)
   (await-flag xgl-usgn32)) ;; changed from xgl-boolean


(def-xgl-macro-function (XGL-CONTEXT-PUSH (:return-type :null) (:name "_xgl_context_push"))
	"Saves the current state of the Context on an internal stack.  Each Context
	has its own independent stack. attr_list is a pointer to a list of
	attributes to be pushed on the stack; the end of the list is indicated by a
	NULL value. If the attribute list is NULL, all pushable attributes
	associated with the Context are saved."
   (ctx xgl-ctx)
   (attr-list (:pointer xgl-attribute)))


(def-xgl-macro-function (XGL-PICK-CLEAR (:return-type :null) (:name "_xgl_pick_clear"))
	"The xgl_pick_clear function clears the pick buffer associated with the
	Context ctx to the nothing-picked state."
   (ctx xgl-ctx))


(def-xgl-macro-function (XGL-PICK-GET-IDENTIFIERS (:return-type :null) (:name "_xgl_pick_get_identifiers"))
	"Returns the identifiers of picked primitives stored in the Context ctx into
	the pick_id_list. The application must have allocated pick_id_list to hold
	as many Xgl_pick_info structures as are in the Context pick buffer. The size
	of the Context pick buffer can be found from the attribute
	XGL_CTX_PICK_BUFFER_SIZE ."
   (ctx xgl-ctx)
   (count (:pointer xgl-usgn32))
   (pick-id-list (:pointer xgl-pick-info)))


(def-xgl-function (XGL-STROKE-FONT-CREATE
		   (:return-type xgl-sfont) 
		   (:name "_xgl_stroke_font_create")
		   (:max-rest-args 512))
	"The Stroke Font operator xgl_stroke_font_create returns a unique handle for
	the stroke font defined by font_name."
   (font-name (:pointer char))
   &rest attributes)


(def-xgl-macro-function (XGL-STROKE-TEXT-EXTENT (:return-type :null) (:name "_xgl_stroke_text_extent"))
	"This operator computes a rectangle in text local coordinates that completely
	encompasses the text string. The argument ctx contains the stroke font
	object and the stroke text attributes necessary to compute the rectangular
	box returned in the argument rect."
   (ctx xgl-ctx)
   (string (:pointer char))
   (rect (:pointer xgl-bounds-f2d))
   (cat-pt (:pointer xgl-pt-f2d)))


(def-xgl-macro-function (XGL-LIGHT-COPY (:return-type :null) (:name "_xgl_light_copy"))
	"xgl_light_copy() makes a copy of a Light. All the state information of a
	Source Light is transferred to a Destination Light. The state information
	consists of the values of all attributes."
   (dest-light xgl-light)
   (src-light xgl-light))


(def-xgl-function (XGL-LIGHT-CREATE 
		   (:return-type xgl-light) 
		   (:name "_xgl_light_create")
		   (:max-rest-args 512))
	"xgl_light_create() creates a new Light and sets initial values of the
	specified attributes."
   &rest attributes)


(def-xgl-function (XGL-LINE-PATTERN-CREATE 
		   (:return-type xgl-lpat) 
		   (:name "_xgl_line_pattern_create")
		   (:max-rest-args 512))
	"Creates a line pattern object. To attach the line pattern to the context,
	set the context attribute XGL_CTX_LINE_PATTERN(3) to this pattern object.
	Setting XGL_CTX_LINE_STYLE to XGL_LINE_PATTERNED, will cause a patterned
	line to be drawn. XGL_CTX_LINE_COLOR determines what the color of the line
	will be. If XGL_CTX_LINE_STYLE is set to XGL_CTX_LINE_ALT_PATTERNED, the
	line is patterned alternately with dashes of XGL_CTX_LINE_ALT_COLOR and
	XGL_CTX_LINE_COLOR."
   &rest attributes)


(def-xgl-macro-function (XGL-CONTEXT-COPY-RASTER (:return-type :null) (:name "_xgl_context_copy_raster"))
	"xgl_context_copy_raster copies a rectangular block of pixels from the source
	raster src_ras to the raster associated with the destination context
	dest_ctx. The area that is copied is specified by a rectangular region,
	rectangle, from the source raster and copied into the destination raster
	starting at a position specfied by position. If the position is a NULL
	pointer, the top and left corner position is used. If the rectangle is a
	NULL pointer the maximum area from the source raster is copied."
   (dest-ctx xgl-ctx)
   (rectangle (:pointer xgl-bounds-i2d))
   (position (:pointer xgl-pt-i2d))
   (src-ras xgl-ras))



#+ignore
(def-xgl-macro-function (XGL-CONTEXT-GET-PIXEL (:return-type xgl-boolean) (:name "_xgl_context_get_pixel"))
	"xgl_context_get_pixel gets the color value of a pixel located at position in
	the raster associated with the context ctx."
   (ctx xgl-ctx)
   (position (:pointer xgl-pt-i2d))
   (value (:pointer xgl-color)))


(def-xgl-macro-function (XGL-CONTEXT-NEW-FRAME (:return-type :null) (:name "_xgl_context_new_frame"))
	"The Context operator xgl_context_new_frame is used to clear the region of
	the DC(Device Coordinate) viewport to the background color, specified by the
	value of XGL_CTX_BACKGROUND_COLOR(3). The bits defined by the attribute
	XGL_CTX_PLANE_MASK(3) are used to determine which planes on the Device are
	cleared. The value of the attribute XGL_CTX_- ROP(3) is not used during the
	clear operation."
   (ctx xgl-ctx))


(def-xgl-macro-function (XGL-CONTEXT-SET-PIXEL (:return-type :null) (:name "_xgl_context_set_pixel"))
	"The operator xgl_context_set_pixel sets the color value of a pixel located
	at the position given by position in the raster associated with the Context
	ctx with the color value of value."
   (ctx xgl-ctx)
   (position (:pointer xgl-pt-i2d))
   (value (:pointer xgl-color)))


(def-xgl-macro-function (XGL-MULTI-SIMPLE-POLYGON (:return-type :null) (:name "_xgl_multi_simple_polygon"))
	"xgl_multi_simple_polygon() draws a set of simple polygons according to the
	parameter list and the graphics state described in the context ctx, which
	may be either a 2D or 3D context. All of the context attributes that
	directly affect the display of polygons are listed in the
	xgl_multi_simple_polygon(3) man page."
   (ctx xgl-ctx)
   (flags xgl-facet-flags)
   (facets (:pointer xgl-facet-list))
   (bbox (:pointer xgl-bbox))
   (num-pt-lists xgl-usgn32)
   (pl (:pointer xgl-pt-list)))


(def-xgl-macro-function (XGL-MULTIARC (:return-type :null) (:name "_xgl_multiarc"))
	"xgl_multiarc() draws a list of counterclockwise (CCW) arcs of a circle
	according to the graphics state described in the Context ctx. Each arc in
	the list is transformed by the current transformation matrix(see
	XGL_CTX_VIEW_TRANS(3) and XGL_CTX_MODEL_TRANS(3) ) and drawn in the plane of
	the view surface."
   (ctx xgl-ctx)
   (arc-list (:pointer xgl-arc-list)))


(def-xgl-macro-function (XGL-MULTICIRCLE (:return-type :null) (:name "_xgl_multicircle"))
	"xgl_multicircle() draws a list of circles according to the graphics state
	described in the Context ctx. The center and radius of each circle in the
	list are transformed by the current transformation matrix(see
	XGL_CTX_VIEW_TRANS(3) and XGL_CTX_MODEL_TRANS(3) ) and drawn in the plane of
	the view surface. If the composite view transformation has unequal scaling
	along the X and Y axes, then each circle will be drawn as an ellipse."
   (ctx xgl-ctx)
   (circle-list (:pointer xgl-circle-list)))


(def-xgl-macro-function (XGL-MULTIMARKER (:return-type :null) (:name "_xgl_multimarker"))
	"xgl_multimarker() draws a marker (a symbol specified by the
	XGL_CTX_MARKER_DESCRIPTION (3) attribute) at each control point in pl->pts.
	The control points in pl->pts are transformed and clipped. If a control
	point is outside the clipping bounds, no marker is drawn. If the control
	point is inside, a marker is drawn; however, the symbol is clipped at the
	clipping bounds."
   (ctx xgl-ctx)
   (pl (:pointer xgl-pt-list)))


(def-xgl-macro-function (XGL-MULTIPOLYLINE (:return-type :null) (:name "_xgl_multipolyline"))
	"xgl_multipolyline() draws a list of unconnected polylines according to the
	graphics state described in the Context ctx. A polyline is defined by a list
	of n vertices v(0), v(1), ..., v(n-1). The vertices form a series of
	connected line segments where a line segment is defined by vertex v(i) and
	v(i+1), for i = 0 to(n-1)."
   (ctx xgl-ctx)
   (bounding-box (:pointer xgl-bbox))
   (num-pt-lists xgl-usgn32)
   (pl (:pointer xgl-pt-list)))


(def-xgl-macro-function (XGL-MULTIRECTANGLE (:return-type :null) (:name "_xgl_multirectangle"))
	"xgl_multirectangle() draws a list of rectangles according to the graphics
	state described in the Context ctx. Each rectangle in the list is
	transformed by the current transformation matrix (see XGL_CTX_VIEW_TRANS(3)
	and XGL_CTX_MODEL_TRANS(3) ) and drawn in the plane of the view surface."
   (ctx xgl-ctx)
   (rect-list (:pointer xgl-rect-list)))


#+ignore
(def-xgl-macro-function (XGL-NU-BSPLINE-CURVE (:return-type :null) (:name "_xgl_nu_bspline_curve"))
	"Generates a Non-Uniform, B-Spline(NURBS) curve of a specified order based on
	a list of knots in parameter space and a list of control points. Either a
	rational or non-rational B-spline is selected depending on the type of the
	control points given in parameter. A parameter range can be specified over
	which the independent variable is evaluated."
   (ctx xgl-ctx)
   (curve xgl-nurbs-curve))


(def-xgl-macro-function (XGL-POLYGON (:return-type :null) (:name "_xgl_polygon"))
	"The general polygon function xgl_polygon draws a single polygon according to
	the parameter list and the graphics state described in the context ctx,
	which may be either a 2D or 3D context. All of the context attributes that
	directly affect the display of polygons are listed in the xgl_polygon(3)
	man page.

	Color is determined in a somewhat baroque manner, depending on the
	value of facet_type"
   (ctx xgl-ctx)
   (facet-type xgl-facet-type)
   (facet (:pointer xgl-facet))
   (bbox (:pointer xgl-bbox))
   (num-pt-lists xgl-usgn32)
   (pl (:pointer xgl-pt-list)))


#+ignore
(def-xgl-macro-function (XGL-POLYHEDRON (:return-type :null) (:name "_xgl_polyhedron"))
	"The function xgl_polyhedron draws multiple general polygons according to the
	parameter list and the graphics state described in the context ctx, which
	may be either a 2D or 3D context. All of the context attributes that
	directly affect the display of triangle strips are listed in the
	xgl_polyhedron(3) man page."
   (ctx xgl-ctx)
   (facets (:pointer xgl-facet-list))
   (pts (:pointer xgl-pt-list))
   (polyhedron (:pointer xgl-polyhedron)))


(def-xgl-macro-function (XGL-QUADRILATERAL-MESH (:return-type :null) (:name "_xgl_quadrilateral_mesh"))
	"The function xgl_quadrilateral_mesh draws a quadrilateral (quad) mesh
	according to the parameter list and the graphics state described in the
	context ctx, which may be a 3D context only. All of the context attributes
	that directly affect the display of quad meshes are listed in the
	xgl_quadrilateral_mesh(3) man page"
   (ctx xgl-ctx)
   (row-dim xgl-usgn32)
   (col-dim xgl-usgn32)
   (facets (:pointer xgl-facet-list))
   (pl (:pointer xgl-pt-list)))


(def-xgl-macro-function (XGL-STROKE-TEXT-2D (:return-type :null) (:name "_xgl_stroke_text_2d"))
	"This 2D Context operator renders a string indexed by the characters in str
	using the Context attributes within ctx."
   (ctx xgl-2d-ctx)
   (str (:pointer char))
   (pos (:pointer xgl-pt-f2d)))


#+ignore
(def-xgl-macro-function (XGL-STROKE-TEXT-3D (:return-type :null) (:name "_xgl_stroke_text_3d"))
	"This 3D context operator renders a string indexed by the
	characters in str using the context attributes within ctx."
   (ctx xgl-3d-ctx)
   (str (:pointer char))
   (pos (:pointer xgl-pt-f3d))
   (dir (:pointer xgl-vector3)))


(def-xgl-macro-function (XGL-TRIANGLE-STRIP (:return-type :null) (:name "_xgl_triangle_strip"))
	"The function xgl_triangle_strip draws a triangle strip according to the
	parameter list and the graphics state described in the context ctx, which
	may be a 3D context only. All of the context attributes that directly affect
	the display of triangle strips are listed in xgl_triangle_strip(3) man page."
   (ctx xgl-ctx)
   (facets (:pointer xgl-facet-list))
   (pl (:pointer xgl-pt-list)))


(def-xgl-function (XGL-MEMORY-RASTER-DEVICE-CREATE 
		   (:return-type xgl-mem-ras) 
		   (:name "_xgl_memory_raster_device_create")
		   (:max-rest-args 512))
	"Creates a Memory Raster Device object. The pixels which define a Memory
	Raster Device are in the application's memory space; they are not visible."
   &rest attributes)

(def-xgl-function (XGL-WINDOW-RASTER-DEVICE-CREATE 
		   (:return-type xgl-win-ras) 
		   (:name "_xgl_window_raster_device_create")
		   (:max-rest-args 512))
	"Creates a Window Raster Device object. The pixels which define a Window
	Raster Device are in a specific \"window\" on graphics framebuffer which is
	managed by a window system.  The application must create the window before
	creating an XGL Window Raster Device on it. A window can have only one (1)
	Window Raster Device associated with it."
   (type xgl-window-type)
   (win-id (:pointer xgl-x-window))
   &rest attributes)


(def-xgl-function (XGL-WINDOW-RASTER-RESIZE (:return-type :null) (:name "_xgl_window_raster_resize"))
	"When an application gets a window resize event from the window system, it
	can call xgl_window_raster_resize() to inform XGL of the new window size.
	This operator is necessary only when the value of attribute XGL_WIN_RAS_TYPE
	is either XGL_WIN_PIXWIN or XGL_WIN_X because for these cases XGL cannot
	trap window resize events."
   (ras xgl-win-ras))


(def-xgl-function (XGL-OPEN 
		   (:return-type xgl-sys-state) 
		   (:name "_xgl_open")
		   (:max-rest-args 512))
	"A single System State object is created and initialized when xgl_open is
	invoked. If successful, a handle to the System State object is returned
	which may only be destroyed by a call to xgl_close(3) with the specified
	handle."
   &rest attributes)



(def-xgl-macro-function (XGL-CLOSE (:return-type :null) (:name "_xgl_close"))
	"This operator is invoked using the handle of the XGL System State object
	created by a previous call to xgl_open(3).  When xgl_close is executed, the
	System State object and all associated resources that have been allocated
	during the current XGL session are destroyed, and XGL is terminated."
   (system-state xgl-sys-state))


(def-xgl-macro-function (XGL-OBJECT-DESTROY (:return-type :null) (:name "_xgl_object_destroy"))
	"xgl_object_destroy destroys the specified object by freeing all resources
	associated with the XGL object represented by handle. A user may only
	destroy objects that he has specifically created."
   (handle xgl-obj))


(def-xgl-macro-function (XGL-OBJECT-GET (:return-type :null) (:name "_xgl_object_get"))
	"xgl_object_get returns the value of the attribute attr of the object obj.
	The parameter val is a pointer to a memory location into which XGL returns
	the attribute's value. The application program is responsible for ensuring
	that val points to a memory area of the size needed by the attribute and for
	allocating the memory area. The manual page for each attribute describes the
	data type that should be passed to xgl_object_get for that attribute."
   (obj xgl-obj)
   (attr xgl-attribute)
   (val (:pointer void)))


(def-xgl-function (XGL-OBJECT-SET 
		   (:return-type :null) 
		   (:name "_xgl_object_set")
		   (:max-rest-args 512))
	"The xgl_object_set operator assigns a given value to a attribute in the
	object obj. Multiple attributes can be updated with a single call to
	xgl_object_set."
   (obj xgl-obj)
   &rest attributes)


(def-xgl-macro-function (XGL-TRANSFORM-COPY (:return-type :null) (:name "_xgl_transform_copy"))
	"xgl_transform_copy() copies the contents of the matrix associated with a
	Source Transform to the matrix associated with a Destination Transform. The
	Destination Transform retains its original data type and dimension, even if
	they differ from those of the Source Transform. Thus, this operator provides
	a means of converting a transform of one type and dimension to another."
   (dest-trans xgl-trans)
   (src-trans xgl-trans))


(def-xgl-function (XGL-TRANSFORM-CREATE 
		   (:return-type xgl-trans) 
		   (:name "_xgl_transform_create")
		   (:max-rest-args 512))
	"xgl_transform_create() creates a new Transform, initializes it as an
	Identity Transform, and sets initial values of the specified attributes."
   &rest attributes)


(def-xgl-macro-function (XGL-TRANSFORM-IDENTITY (:return-type :null) (:name "_xgl_transform_identity"))
	"xgl_transform_identity() sets a Transform's matrix to the identity. The data
	type and dimension of this matrix are given by the values of the Transform's
	attributes XGL_TRANS_DATA_TYPE and XGL_TRANS_DIMENSION."
   (trans xgl-trans))


(def-xgl-macro-function (XGL-TRANSFORM-INVERT (:return-type xgl-trans) (:name "_xgl_transform_invert"))
	"nxgl_transform_invert() inverts a Transform's matrix. The numerical accuracy
	depends on the Transform's data type as given by the attribute
	XGL_TRANS_DATA_TYPE. The result will be very coarse for Transforms of type
	XGL_DATA_INT."
   (dest-trans xgl-trans)
   (src-trans xgl-trans))


(def-xgl-macro-function (XGL-TRANSFORM-MULTIPLY (:return-type :null) (:name "_xgl_transform_multiply"))
	"xgl_transform_multiply() multiplies two Transforms. All Transforms passed to
	this operator must have the same dimension as given by XGL_TRANS_DIMENSION.
	However, the Transforms need not have the same data type as given by
	XGL_TRANS_DATA_TYPE."
   (dest-trans xgl-trans)
   (left-src-trans xgl-trans)
   (right-src-trans xgl-trans))


(def-xgl-macro-function (XGL-TRANSFORM-POINT (:return-type :null) (:name "_xgl_transform_point"))
	"xgl_transform_point() transforms a single point. This operator treats the
	point as a row vector and multiplies it by a Transform's matrix. The result
	is stored back in the memory allocated for the point, overwriting the
	untransformed point. If the transformation results in a point with a
	homogeneous w coordinate not equal to 1 then the x, y, and z(for 3D)
	coordinates are normalized by w to produce an ordinary point with w = 1. The
	dimension of the Transform as given by XGL_TRANS_DIMENSION must match the
	dimension of the point. A 2D point must be given with a 2D Transform;
	similarly, a 3D point must be given with a 3D Transform. However, the data
	type of the Transform as given by XGL_TRANS_DATA_TYPE can be different from
	that of the point."
   (trans xgl-trans)
   (point (:pointer xgl-pt)))


(def-xgl-macro-function (XGL-TRANSFORM-POINT-LIST (:return-type :null) (:name "_xgl_transform_point_list"))
	"xgl_transform_point_list() transforms a list of points.  This operator
	treats each point as a row vector and multiplies it by a Transform's matrix.
	If the transformation results in a point with a homogeneous w coordinate not
	equal to 1 and the destination point list has no storage for the w
	coordinate, then the x, y, and z(for 3D) coordinates are normalized by w to
	produce an ordinary point with w = 1.  The dimension of the Transform as
	given by XGL_TRANS_DIMENSION must match the dimension of the points in the
	list. A list of 2D points must be given with a 2D Transform; similarly, a
	list of 3D points must be given with a 3D Transform. However, the data type
	of the Transform as given by XGL_TRANS_DATA_TYPE can be different from that
	of the points in the list."
   (trans xgl-trans)
   (src-pt-list (:pointer xgl-pt-list))
   (dest-pts (:pointer void)))


(def-xgl-macro-function (XGL-TRANSFORM-READ (:return-type :null) (:name "_xgl_transform_read"))
	"xgl_transform_read() reads a Transform's matrix into an
	array supplied by the application."
   (src-trans xgl-trans)
   (matrix (:pointer void)))


(def-xgl-macro-function (XGL-TRANSFORM-ROTATE (:return-type :null) (:name "_xgl_transform_rotate"))
	"xgl_transform_rotate() combines a given Transform with a Rotation Transform
	constructed with the given parameters.  The Rotation Transform can replace
	the given Transform, or it can be preconcatenated or postconcatenated with
	the given Transform."
   (trans xgl-trans)
   (angle :double-float)
   (axis xgl-axis)
   (update xgl-trans-update))


(def-xgl-macro-function (XGL-TRANSFORM-SCALE (:return-type :null) (:name "_xgl_transform_scale"))
	"xgl_transform_scale() combines a given Transform with a Scale Transform
	constructed with the given parameters. The Scale Transform can replace the
	given Transform, or it can be preconcatenated or postconcatenated with the
	given Transform."
   (trans xgl-trans)
   (scale-factors (:pointer xgl-pt))
   (update xgl-trans-update))


(def-xgl-macro-function (XGL-TRANSFORM-TRANSLATE (:return-type :null) (:name "_xgl_transform_translate"))
	"xgl_transform_translate() combines a given Transform with a Translation
	Transform constructed with the given parameters.  The Translation Transform
	can replace the given Transform, or it can be preconcatenated or
	postconcatenated with the given Transform."
   (trans xgl-trans)
   (offset (:pointer xgl-pt))
   (update xgl-trans-update))


(def-xgl-macro-function (XGL-TRANSFORM-TRANSPOSE (:return-type :null) (:name "_xgl_transform_transpose"))
	"xgl_transform_transpose() transposes a Transform's matrix."
   (dest-trans xgl-trans)
   (src-trans xgl-trans))


(def-xgl-macro-function (XGL-TRANSFORM-WRITE (:return-type :null) (:name "_xgl_transform_write"))
	"xgl_transform_write() writes an array supplied by the application into a
	Transform's matrix."
   (dest-trans xgl-trans)
   (matrix (:pointer void)))

