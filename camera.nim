import glm, opengl

type
  Camera* = object
    x*: GLfloat
    y*: GLfloat
    z*: GLfloat
    yaw*: GLfloat

proc getViewMatrix*(cam: Camera): Mat4[GLfloat] =
  var cameraMat = glm.lookAt[GLfloat](
    vec3[GLfloat](0, 0, 0), # Position
    vec3[GLfloat](0, 1, 0), # Target
    vec3[GLfloat](0, 0, 1), # Up
  )
  cameraMat = glm.rotateZ(cameraMat, cam.yaw)
  cameraMat = glm.translate(cameraMat, vec3[GLfloat](-cam.x, -cam.y, -cam.z))
  return cameraMat
