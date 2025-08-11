shader_type spatial;

uniform vec3 apex; // The position of the cone's apex (player's position)
uniform vec3 base; // The position of the cone's base (camera's position)
uniform float base_radius; // The radius of the cone's base

// Varying variable to pass data from the vertex shader to the fragment shader
varying vec3 world_pos;

void vertex() {
    // Calculate the world position of the vertex
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    // Calculate the cone's axis vector and the vector from the apex to the pixel
    vec3 axis = base - apex;
    vec3 apex_to_pixel = world_pos - apex;

    // Calculate the projection of the apex-to-pixel vector onto the cone's axis
    float axis_length = length(axis);
    float projection_length = dot(apex_to_pixel, axis) / axis_length;

    // If the pixel is between the apex and the base
    if (projection_length >= 0.0 && projection_length <= axis_length) {
        // Calculate the distance from the pixel to the cone's axis
        vec3 closest_point_on_axis = apex + axis * (projection_length / axis_length);
        float distance_to_axis = length(world_pos - closest_point_on_axis);

        // Calculate the radius of the cone at the current height
        float cone_radius_at_height = base_radius * (projection_length / axis_length);

        // If the pixel is inside the cone, discard it
        if (distance_to_axis < cone_radius_at_height) {
            discard;
        }
    }
}
