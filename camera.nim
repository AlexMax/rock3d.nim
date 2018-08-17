import glm, opengl

type
  Camera* = object
    x*: GLfloat
    y*: GLfloat
    z*: GLfloat
    yaw*: GLfloat
    position: Vec3[GLfloat]
    target: Vec3[GLfloat]
    up: Vec3[GLfloat]

proc getViewMatrix*(cam: Camera): Mat4[GLfloat] =
  let cameraPos = vec3[GLfloat](cam.x, cam.y, cam.z)
  let cameraTarget = vec3[GLfloat](cam.x, cam.y + 1, cam.z)
  let cameraUp = vec3[GLfloat](0, 0, 1)

  var cameraMat = glm.lookAt[GLfloat](cameraPos, cameraTarget, cameraUp)
  return glm.rotateZ(cameraMat, cam.yaw)
