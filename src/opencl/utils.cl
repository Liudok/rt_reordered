
#include "include/kernel.h"

static float get_random(unsigned int *seed0, unsigned int *seed1) {

	/* hash the seeds using bitwise AND operations and bitshifts */
	*seed0 = 36969 * ((*seed0) & 65535) + ((*seed0) >> 16);
	*seed1 = 18000 * ((*seed1) & 65535) + ((*seed1) >> 16);

	unsigned int ires = ((*seed0) << 16) + (*seed1);

	/* use union struct to convert int to float */
	union {
		float f;
		unsigned int ui;
	} res;

	res.ui = (ires & 0x007fffff) | 0x40000000;  /* bitwise AND, bitwise OR */
	return half_divide((res.f - 2.0f), 2.0f);
}

static void	ft_roots(float2 *t, float a, float b, float c)
{
	float	deskr;

	deskr = b * b - 4 * a * c;
	if (deskr >= 0.f && a != 0.f)
		*t = (float2)(	native_divide(-b + native_sqrt(deskr), 2 * a),
						native_divide(-b - native_sqrt(deskr), 2 * a));
	else
		*t = (float2)(-1, -1);
}

static int	toInt(float3 v)
{
	float3 		t;
	union
	{
		uchar4	byte;
		uint	value;
	}			color;

	t = pow(clamp(v, 0.f, 1.0f), 1.f / 2.2f);
	color.byte[0] = (int)(t.z * 255.0f + .5f);
	color.byte[1] = (int)(t.y * 255.0f + .5f);
	color.byte[2] = (int)(t.x * 255.0f + .5f);
	color.byte[3] = 0x0;
	return (color.value);
}

static void	addSample(global float3 *colors, float3 *color, uint currentSample, int id)
{
	if (currentSample == 0) {
		colors[id] = *color;
	} else {
		const float k1 = currentSample;
		const float k2 = 1.f / (currentSample + 1.f);
		colors[id].x = (colors[id].x * k1  + color->x) * k2;
		colors[id].y = (colors[id].y * k1  + color->y) * k2;
		colors[id].z = (colors[id].z * k1  + color->z) * k2;
	}
}

static void	putPixel(global int *pixels, global float3 *colors, int id)
{
	pixels[id] = toInt(colors[id]);
}
