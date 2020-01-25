#include "cube_coordinate.h"

#include <stdio.h>

VALUE CubeCoordinateClass = Qnil;

typedef struct {
  int cube_size;
  int face_index;
  int x;
  int y;
} CubeCoordinateData;

const rb_data_type_t CubeCoordinateData_type = {
  "CubeTrainer::Native::CubeCoordinateData",
  {NULL, NULL, NULL, NULL},
  NULL, NULL,
  RUBY_TYPED_FREE_IMMEDIATELY
};

#define GetCubeCoordinateData(obj, data) TypedData_Get_Struct((obj), CubeCoordinateData, &CubeCoordinateData_type, (data));

int num_stickers_for_cube_size(const int cube_size) {
  return cube_faces * cube_size * cube_size;
}

int sticker_index(const int cube_size, const FACE_INDEX face_index, const int x, const int y) {
  return face_index * cube_size * cube_size + y * cube_size + x;
}

int CubeCoordinate_sticker_index(const VALUE obj, const int cube_size) {
  CubeCoordinateData* data;
  GetCubeCoordinateData(obj, data);
  if (data->cube_size != cube_size) {
    rb_raise(rb_eArgError, "Cannot use coordinate for cube size %d on a %dx%d cube.", data->cube_size, cube_size, cube_size);
  }
  return sticker_index(cube_size, data->face_index, data->x, data->y);
}

size_t CubeCoordinateData_size(const void* const ptr) {
  return sizeof(CubeCoordinateData);
}

VALUE CubeCoordinate_alloc(const VALUE klass) {
  CubeCoordinateData* data;
  VALUE object = TypedData_Make_Struct(klass, CubeCoordinateData, &CubeCoordinateData_type, data);
  data->cube_size = 0;
  data->face_index = 0;
  data->x = 0;
  data->y = 0;
  return object;
}

int inverted_index(const int cube_size, const int index) {
  return cube_size - 1 - index;
}

int transform_index(const FACE_INDEX index_base_face_index, const int cube_size, const int index) {
  if (index_base_face_index == axis_index(index_base_face_index)) {
    return index;
  } else {
    return inverted_index(cube_size, index);
  }
}

int switch_axes(const FACE_INDEX x_base_face_index, const FACE_INDEX y_base_face_index) {
  return axis_index(x_base_face_index) < axis_index(y_base_face_index);
}

VALUE CubeCoordinate_initialize(const VALUE self,
                                const VALUE cube_size,
                                const VALUE face_symbol,
                                const VALUE x_base_face_symbol,
                                const VALUE y_base_face_symbol,
                                const VALUE x_num,
                                const VALUE y_num) {
  Check_Type(cube_size, T_FIXNUM);
  Check_Type(face_symbol, T_SYMBOL);
  Check_Type(x_base_face_symbol, T_SYMBOL);
  Check_Type(y_base_face_symbol, T_SYMBOL);
  Check_Type(x_num, T_FIXNUM);
  Check_Type(y_num, T_FIXNUM);
  const int n = NUM2INT(cube_size);
  const int untransformed_x = NUM2INT(x_num);
  const int untransformed_y = NUM2INT(y_num);
  if (untransformed_x < 0 || untransformed_x >= n) {
    rb_raise(rb_eArgError, "Invalid value %d for x with cube size %d.", untransformed_x, n);
  }
  if (untransformed_y < 0 || untransformed_y >= n) {
    rb_raise(rb_eArgError, "Invalid value %d for y with cube size %d.", untransformed_y, n);
  }
  const FACE_INDEX on_face_index = face_index(face_symbol);
  const FACE_INDEX x_base_face_index = face_index(x_base_face_symbol);
  const FACE_INDEX y_base_face_index = face_index(y_base_face_symbol);
  if (axis_index(x_base_face_index) == axis_index(on_face_index)) {
    rb_raise(rb_eArgError, "Invalid value for x_base_face_symbol.");
  }
  if (axis_index(y_base_face_index) == axis_index(on_face_index)) {
    rb_raise(rb_eArgError, "Invalid value for y_base_face_symbol.");
  }
  if (axis_index(x_base_face_index) == axis_index(y_base_face_index)) {
    rb_raise(rb_eArgError, "Incompatible values for x_base_face_symbol and y_base_face_symbol.");
  }
  CubeCoordinateData* data;
  GetCubeCoordinateData(self, data);
  const int transformed_x = transform_index(x_base_face_index, n, untransformed_x);
  const int transformed_y = transform_index(y_base_face_index, n, untransformed_y);
  data->cube_size = n;
  data->face_index = on_face_index;
  if (switch_axes(x_base_face_index, y_base_face_index)) {
    data->x = transformed_y;
    data->y = transformed_x;
  } else {
    data->x = transformed_x;
    data->y = transformed_y;
  }
  return self;
}

void init_cube_coordinate_class_under(const VALUE NativeModule) {
  CubeCoordinateClass = rb_define_class_under(NativeModule, "CubeCoordinate", rb_cObject);
  rb_define_alloc_func(CubeCoordinateClass, CubeCoordinate_alloc);
  rb_define_method(CubeCoordinateClass, "initialize", CubeCoordinate_initialize, 6);
}
