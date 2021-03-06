static float sphere_intersect(global t_sphere* obj, t_ray ray) {
	float3 oc;
	float b;
	float dis;
	float t;

	oc = obj->origin - ray.o;
	b = dot(oc, ray.d);
	dis = b * b - dot(oc, oc) + obj->r2;
	if (dis < 0)
		return 0;
	dis = sqrt(dis);
	t = b - dis;
	if (t > EPSILON)
		return t;
	t = b + dis;
	if (t > EPSILON)
		return t;
	return (INFINITY);
}

static float plane_intersect(global t_plane* obj, t_ray ray) {
	float denom;
	float3 oc;

	if ((denom = dot(ray.d, obj->normal)) == 0)
		return (INFINITY);
	oc = ray.o - obj->origin;
	return (-dot(oc, obj->normal) / denom);
}

static float cylinder_intersect(global t_cylinder* obj, t_ray ray, float* m) {
	float a;
	float b;
	float c;
	float3 oc;
	float2 t;

	oc = ray.o - obj->origin;
	t.x = dot(ray.d, normalize(obj->normal));
	t.y = dot(oc, normalize(obj->normal));
	a = dot(ray.d, ray.d) - t.x * t.x;
	b = 2 * (dot(ray.d, oc) - t.x * t.y);
	c = dot(oc, oc) - t.y * t.y - obj->r2;
	ft_roots(&t, a, b, c);
	if ((t.x < 0.0f) && (t.y < 0.0f))
		return (INFINITY);
	if ((t.x < 0.0f) || (t.y < 0.0f)) {
		a = (t.x > t.y) ? t.x : t.y;
		*m = dot(ray.d, normalize(obj->normal)) * a +
			dot(oc, fast_normalize(obj->normal));
		return ((*m <= obj->height) && (*m >= EPSILON) ? t.x : INFINITY);
	}
	a = (t.x < t.y) ? t.x : t.y;
	*m = dot(ray.d, normalize(obj->normal)) * a +
		dot(oc, fast_normalize(obj->normal));
	if ((*m <= obj->height) && (*m >= EPSILON))
		return (a);
	a = (t.x >= t.y) ? t.x : t.y;
	*m = dot(ray.d, normalize(obj->normal)) * a +
		dot(oc, fast_normalize(obj->normal));
	if ((*m <= obj->height) && (*m >= EPSILON))
		return (a);
	return (INFINITY);
}

static float cone_intersect(global t_cone* obj, t_ray ray, float* m) {
	float a;
	float b;
	float c;
	float d;
	float3 oc;
	float2 t;

	oc = ray.o - obj->origin;
	t.x = dot(ray.d, obj->normal);
	t.y = dot(oc, obj->normal);
	d = 1 + obj->half_tangent * obj->half_tangent;
	a = dot(ray.d, ray.d) - d * t.x * t.x;
	b = 2 * (dot(ray.d, oc) - d * t.x * t.y);
	c = dot(oc, oc) - d * t.y * t.y;
	ft_roots(&t, a, b, c);
	if (t.x < 0.0f && t.y < 0.0f)
		return (INFINITY);
	if (t.x < 0.0f || t.y < 0.0f) {
		a = (t.x > t.y) ? t.x : t.y;
		*m = dot(ray.d, obj->normal) * a +
			dot(oc, obj->normal);
		return ((*m <= obj->m2) && (*m >= obj->m1) ? a : INFINITY);
	}
	a = (t.x < t.y) ? t.x : t.y;
	*m = dot(ray.d, obj->normal) * a +
		dot(oc, obj->normal);
	if ((*m <= obj->m2) && (*m >= obj->m1))
		return (a);
	a = (t.x >= t.y) ? t.x : t.y;
	*m = dot(ray.d, obj->normal) * a +
		dot(oc, obj->normal);
	if ((*m <= obj->m2) && (*m >= obj->m1))
		return (a);
	return (INFINITY);
}

static float disk_intersect(global t_disk* obj, t_ray ray) {
	float denom;
	float3 oc;
	float t;
	float3 pos;

	if ((denom = dot(ray.d, obj->normal)) == 0)
		return (INFINITY);
	oc = ray.o - obj->origin;
	t = native_divide(-dot(oc, obj->normal), denom);
	if (t < 0)
		return (INFINITY);
	pos = ray.o + t * ray.d;
	pos -= obj->origin;
	if (dot(pos, pos) <= obj->radius2)
		return (t);
	return (INFINITY);
}

static void sort(float3 *ua, float2 *l)
{
	if (fabs((*ua)[0]) > fabs((*ua)[1]) && fabs((*ua)[0]) > fabs((*ua)[2]))
	{
		(*l)[0] = (*ua)[0];
		(*l)[1] = fabs((*ua)[1]) > fabs((*ua)[2]) ? (*ua)[1] : (*ua)[2];
	}
	else if (fabs((*ua)[1]) > fabs((*ua)[0]) && fabs((*ua)[1]) > fabs((*ua)[2]))
	{
		(*l)[0] = (*ua)[1];
		(*l)[1] = fabs((*ua)[0]) > fabs((*ua)[2]) ? (*ua)[0] : (*ua)[2];
	}
	else
	{
		(*l)[0] = (*ua)[2];
		(*l)[1] = fabs((*ua)[0]) > fabs((*ua)[1]) ? (*ua)[0] : (*ua)[1];
	}
}

static void negative_discr_solution(t_equation *e)
{
	float 	n;
	float 	bq3;
	float 	beta;
	float 	a3;
	float3 	ua;

	n = sqrt(e->b);
	bq3 = n * n * n;
	beta = (e->br / bq3 < 1.0f) ? acos(e->br / bq3) : 0.0f;
	a3 = -2.0f * n;
	ua[0] = a3 * cos(beta / 3.0f) - e->c / 3.0f;
	ua[1] = a3 * cos((beta + 2.0f * M_PI) / 3.0f) - e->c / 3.0f;
	ua[2] = a3 * cos((beta - 2.0f * M_PI) / 3.0f) - e->c / 3.0f;
	e->flag = false;
	sort(&ua, &(e->l));
	if (e->l[0] >= 0.0f)
	{
		e->real1 = sqrt(e->l[0]);
		e->im1 = 0.0f;
	}
	else
	{
		e->im1 = sqrt(-e->l[0]);
		e->real1 = 0.0f;
	}
	if (e->l[1] >= 0.0f)
	{
		e->im2 = 0.0f;
		e->real2 = sqrt(e->l[1]);
	}
	else
	{
		e->real2 = 0.0f;
		e->im2 = sqrt(-e->l[1]);
	}
}

static void positive_discr_solution(t_equation *e)
{
	float 	n;
	float 	a3;
	float3 	ua;
	float 	n2;
	float 	u2;

	n = (e->br < 0.0f) ? -1.0f : 1.0f;
	a3 = -n * cbrt(fabs(e->br) + sqrt(e->discr));
	ua[0] = a3 + e->b / a3 - e->c / 3.0f;
	ua[1] = -0.5f * ((a3 * a3 + e->b) / a3) - e->c / 3.0f;
	ua[2] = -(sqrt(3.0f) / 2.0f) * fabs(a3 - (e->b / a3));
	e->flag = true;
	n2 = sqrt(sqrt(ua[1] * ua[1] + ua[2] * ua[2]));
	u2 = atan2(ua[2], ua[1]);
	e->real1 = n2 * cos(u2 * 0.5f);
	e->im1 = n2 * sin(u2 * 0.5f);
	e->real2 = e->real1;
	e->im2 = -e->im1;
}

static int	fourth_degree_equation(float4 *t, float4 a)
{
	float	res;
	float	im_re1;
	float	im_re2;
	float	komp;
	t_equation 	e;

	e.aa = a[0] * a[0];
	e.pp = a[1] - 0.375f * e.aa;
	e.rr = a[3] - 0.25f * (a[0] * a[2] - 0.25f * e.aa * (a[1] - 0.1875f * e.aa));
	e.q2 = a[2] - 0.5f * a[0] * (a[1] - 0.25f * e.aa);
	e.c = 0.5f * e.pp;
	e.aa = 0.25f * (0.25f * e.pp * e.pp - e.rr);
	e.b = e.c * e.c / 9.0f - e.aa / 3.0f;
	e.br = e.c * e.c * e.c / 27.0f - e.c * e.aa / 6.0f - (0.125f * e.q2 * 0.125f * e.q2) / 2.0f;
	e.discr = ((e.br * e.br) - (e.b * e.b * e.b));
	if (e.discr < 0.0f)
		negative_discr_solution(&e);
	else
		positive_discr_solution(&e);
	im_re1 = e.im1 * e.im1 + e.real1 * e.real1;
	im_re2 = e.im2 * e.im2 + e.real2 * e.real2;
	komp = e.im1 * e.im2 - e.real1 * e.real2;
	res = e.q2 * 0.125f * komp / im_re1 / im_re2;
	(*t)[0] = e.real1 + e.real2 + res - a[0] * 0.25f;
	(*t)[1] = -e.real1 - e.real2 + res - a[0] * 0.25f;
	(*t)[2] = -e.real1 + e.real2 - res - a[0] * 0.25f;
	(*t)[3] = e.real1 - e.real2 - res - a[0] * 0.25f;
	if (!e.flag && e.l[0] >= 0.0f && e.l[1] >= 0.0f)
		return (4);
	else if (!e.flag)
		return (0);
	else
		return (2);
}

static float  torus_intersect(global t_torus* obj, t_ray ray)
{
	int		count_roots;
	int		i;
	float4	u;
	float4	x;
	float	ret;
	float3 	oc;
	float4	qq;
	float4 	dots;

	oc = obj->origin - ray.o;
	float b = dot(oc, ray.d);
	float dis = b * b - dot(oc, oc) + (obj->big_radius2 + EPSILON) * M_PI;
	if (dis < 0)
		return INFINITY;
	dis = sqrt(dis);
	float t = b - dis;
	if (t < EPSILON)
	{
		t = b + dis;
		if (t < EPSILON)
			return (INFINITY);
	}
	ray.o = ray.o + ray.d * (t - 2.f * EPSILON);
	oc = ray.o - obj->origin;
	dots[0] = dot(oc, normalize(obj->normal));
	dots[1] = dot(ray.d, normalize(obj->normal));
	dots[2] = dot(oc, oc);
	dots[3] = dot(oc, ray.d);
	qq[0] = 1.0f - dots[1] * dots[1];
	qq[1] = 2.0f * (dots[3] - dots[0] * dots[1]);
	qq[2] = dots[2] - dots[0] * dots[0];
	qq[3] = dots[2] + obj->big_radius2 - obj->small_radius2;
	u[0] = 4.0f * dots[3];
	u[1] = 2.0f * qq[3] + u[0] * u[0] * 0.25f - 4.0f * obj->big_radius2 * qq[0];
	u[2] = u[0] * qq[3] - 4.0f * obj->big_radius2 * qq[1];
	u[3] = qq[3] * qq[3] - 4.0f * obj->big_radius2 * qq[2];
	count_roots = fourth_degree_equation(&x, u);
	i = -1;
	ret = INFINITY;
	while (count_roots > ++i)
		if (x[i] < ret && x[i] > EPSILON)
			ret = x[i];
	return (ret + t);
}

static float  triangle_intersect(global t_triangle *obj, t_ray ray)
{
	float	denom;
	float3	oc;
	float3	normal;
	float 	t;
	float3	p;
	float3	edge0;
	float3	edge1;
	float3	edge2;
	float3	c0;
	float3	c1;
	float3	c2;

	edge0 = obj->vertex1 - obj->vertex0;
	edge1 = obj->vertex2 - obj->vertex1;
	edge2 = obj->vertex0 - obj->vertex2;
	normal = normalize(cross(edge0, edge1));

	if ((denom = dot(ray.d, normal)) == 0)
	    return (-1);
	oc = ray.o - obj->vertex0;
	t = -dot(oc, normal) / denom;
	if (t < 0)
	    return (-1);
	p = ray.o + ray.d * t;
	c0 = p - obj->vertex0;
	c1 = p - obj->vertex1;
	c2 = p - obj->vertex2;
	if (dot(normal, cross(edge0, c0)) > 0 && dot(normal, cross(edge1, c1)) > 0 && dot(normal, cross(edge2, c2)) > 0)
	    return (t);
	return (-1);
}

static void		coeffs(float3 *coeff, float3 pos, float3 dir)
{
	float	d_x2;
	float	d_y2;
	float	d_z2;
	float	d_y3;
	int		legth;
	float3	rx;
	float	o_x2;
	float	o_y2;
	float	o_z2;

	float	c3;
	float 	kk;
	float	k;
	float	k1;
	float	k2;
	float	k3;
	float	k4;
	float	k5;

	legth = 1;
	rx = pos;
	d_x2 = dir.x * dir.x;
	d_y2 = dir.y * dir.y;
	d_z2 = dir.z * dir.z;
	d_y3 = dir.y * dir.y * dir.y;
	c3 = d_x2 * dir.y + d_y3 - 2.0f * d_x2 * dir.z - 2.0f * d_y2 * dir.z + dir.y * d_z2;
	o_x2 = rx.x * rx.x;
	o_y2 = rx.y * rx.y;
	o_z2 = rx.z * rx.z;
	(*coeff)[2] = (o_x2 * rx.y + rx.y * rx.y * rx.y - 2.0f * o_x2 * rx.z - 2.0f * o_y2 * rx.z + rx.y * o_z2 - 2.0f * pos.x * pos.z - pos.y) / c3;

	kk = 2.0f * dir.z * o_x2;
	k = dir.y * o_x2 - kk;
	kk = 3.0f * dir.y * o_y2;
	k1 = 2.0f * dir.x * rx.x * rx.y + kk;
	k2 = 2.0f * dir.z * o_y2;
	kk = 4.0f * dir.y * rx.y * rx.z;
	k3 = 4.0f * dir.x * rx.x * rx.z + kk;
	kk = dir.y * o_z2;
	k4 = 2.0f * dir.z * rx.y * rx.z + kk;
	kk = 2.0f * dir.x * rx.z * legth;
	k5 = 2.0f * dir.z * rx.x * legth + kk + dir.y * legth * legth;
	(*coeff)[1] = (k + k1 - k2 - k3 + k4 - k5) / c3;

	kk = 2.0f * dir.x * dir.y * rx.x;
	k = kk - 4.0f * dir.x * dir.z * rx.x;
	kk = d_x2 * rx.y + 3.0f * d_y2 * rx.y;
	k1 = kk - 4.0f * dir.y * dir.z * rx.y;
	kk = d_z2 * rx.y - 2.0f * d_x2 * rx.z;
	k2 = kk - 2.0f * d_y2 * rx.z;
	kk = 2.0f * dir.y * dir.z * rx.z;
	k3 = kk - 2.0f * dir.x * dir.z * legth;
	(*coeff)[0] = (k + k1 + k2 + k3) / c3;

}

static int			calculation_coefficients(float3 qa, float3 *s, float q, float r)
{
	float	beta;
	float	ba;
	int		n;

	q = (qa[0] * qa[0] - 3.0f * qa[1]) / 9.0f;
	r = (2.0f * pow(qa[0], 3) - 9.0f * qa[0] * qa[1] + 27.0f * qa[2]) / 54.0f;
	n = -1;
	if (r >= 0.0f)
		n = 1;
	if (pow(r, 2) < pow(q, 3))
	{
		beta = acos(n * sqrt(pow(r, 2) / pow(q, 3)));
		(*s)[0] = -2.0f * sqrt(q) * cos(beta / 3.0f) - qa[0] / 3.0f;
		(*s)[1] = -2.0f * sqrt(q) * cos((beta + 2.0f * M_PI) / 3.0f) - qa[0] / 3.0f;
		(*s)[2] = -2.0f * sqrt(q) * cos((beta - 2.0f * M_PI) / 3.0f) - qa[0] / 3.0f;
		return (3);
	}
	else
	{
		ba = -n * cbrt(fabs(r) + sqrt(pow(r, 2) - pow(q, 3)));
		(*s)[0] = ba + (q / ba) - qa[0] / 3.0f;
		return (1);
	}
	return (0);
}

static float	ft_s(float t, float3 p0)
{
	if (sin(t / 2.0f) > 0.0f)
		return (p0.z / sin(t / 2.0f));
	else
	{
		if (cos(t) > 0.001)
			return ((p0.x / cos(t) - 1) / cos(t / 2));
		else
			return ((p0.y / sin(t) - 1) / cos(t / 2));
	}
}
static int				check_point(float3 p0, float max)
{
	float t;
	float s;

	t = atan2(p0.y, p0.x);
	s = ft_s(t, p0);
	p0.x -= (1 + s * cos(t / 2)) * cos(t);
	p0.y -= (1 + s * cos(t / 2)) * sin(t);
	p0.z -= s * sin(t / 2);
	t = dot(p0, p0);
	if (t > EPSILON)
		return (0);
	if (s >= -max && s <= max)
		return (1);
	else
		return (0);
}

static float  mobius_intersect(global t_mobius* obj, t_ray ray)
{
	float3		a;
	float3		t;
	float3		p0;
	float3		u;

	ray.o = ray.o - obj->origin;
	coeffs(&a, ray.o, ray.d);
	a[1] = calculation_coefficients(a, &t, 0.0f, 0.0f);
	a[0] = 0;
	while (a[0] < a[1])
	{
		if (t[(int)a[0]] > 0.1f)
		{
			u = ray.d * t[(int)a[0]];
			p0 = u + ray.o;
			if (check_point(p0, obj->size))
				return (t[(int)a[0]]);
		}
		a[0]++;
	}
	return (-1);
}

static void swap(float* a, float* b)
{
	float c;
	c = *a;
	*a = *b;
	*b = c;
}

float3	find_normal(global t_object *obj, float3 hit_pos, float m);
static float  cube_intersect(global t_cube *obj, t_ray ray, float* m, global t_object **closest)
{
    float 	t_min;
    float 	t_max;
    float 	t_y_min;
    float 	t_y_max;
    float 	t_z_min;
    float 	t_z_max;
    float2	side = {0, 0};
    float 	t_pipe = MAXFLOAT;

    t_min = (obj->min.x  - ray.o.x) / ray.d.x;
    t_max = (obj->max.x  - ray.o.x) / ray.d.x;
    if (t_min > t_max)
        swap(&t_min, &t_max);
    t_y_min = (obj->min.y  - ray.o.y) / ray.d.y;
    t_y_max = (obj->max.y  - ray.o.y) / ray.d.y;
    if (t_y_min > t_y_max)
        swap(&t_y_min, &t_y_max);
    if (t_min > t_y_max || t_y_min > t_max)
    	return (-1);
    if (t_y_min > t_min)
    {
        side.x = 1;
        t_min = t_y_min;
    }
    if (t_y_max < t_max)
    {
        side.y = 1;
        t_max = t_y_max;
    }
    t_z_min = (obj->min.z - ray.o.z) / ray.d.z;
    t_z_max = (obj->max.z - ray.o.z) / ray.d.z;
    if (t_z_min > t_z_max)
        swap(&t_z_min, &t_z_max);
    if (t_min > t_z_max || t_z_min > t_max)
        return (-1);
    if (t_z_min > t_min)
    {
        side.x = 2;
        t_min = t_z_min;
    }
    if (t_z_max < t_max)
    {
        side.y = 2;
        t_max = t_z_max;
    }

	global t_object *ptr = NULL;
	ptr = (global t_object *)((void *)obj - (void *)&ptr->prim);
	ptr++;
    if (obj->pipes_number)
    {
        int 	i_closet;
        float 	m_current;

        for (int i = 0; i < obj->pipes_number; i++)
        {
            float current = cylinder_intersect(&ptr[i].prim.cylinder, ray, &m_current);
            if (current > EPSILON && current < t_pipe)
            {
                *m = m_current;
                i_closet = i;
                t_pipe = current;
            }
        }
        if (t_pipe < MAXFLOAT)
        {
            float3 pos = ray.o + ray.d * t_pipe;
            float3 normal = find_normal(&ptr[i_closet], pos, *m);
            if (dot(ray.d, normal) > 0.0f)
            {
                *closest = &ptr[i_closet];
                return (t_pipe);
            }
        }
    }
    *closest = NULL;
    if (t_min <= 0)
    {
        *m = side.y;
        t_min = t_max;
    }
    if (t_min > 0)
    {
        float3 pos = ray.o + ray.d * t_min;
		for (int i = 0; i < obj->pipes_number; i++)
        {
            float3 temp = ptr[i].prim.cylinder.origin - pos;
            if (length(temp - dot(temp, ptr[i].prim.cylinder.normal) * ptr[i].prim.cylinder.normal) < ptr[i].prim.cylinder.radius)
            	return (-1);
        }
    }
    *m = side.x;
    return (t_min);
}

static float  sphere_intersect1(global t_sphere *obj, t_ray ray, float2* roots)
{
	float	a;
	float	b;
	float	c;
	float3	oc;
	float2	t;

	oc = ray.o - obj->origin;
	a = dot(ray.d, ray.d);
	b = 2 * dot(ray.d, oc);
	c = dot(oc, oc) - (obj->radius * obj->radius);
	ft_roots(&t, a, b, c);
	if (roots)
		*roots = t;
	if ((t.x < 0.0 && t.y >= 0.0) || (t.y < 0.0 && t.x >= 0.0))
		return t.x > t.y ? t.x : t.y;
	else
		return t.x < t.y ? t.x : t.y;
}

static float	bool_substraction_intersect(global t_object *ptr, t_ray ray,
											global t_object **closest)
{
	float2	roots1;
	float2	roots2;
	float 	t1;
	float 	t2;

	t1 = sphere_intersect1(&ptr->prim.sphere, ray, &roots1);
	ptr++;
	t2 = sphere_intersect1(&ptr->prim.sphere, ray, &roots2);
	if (t1 <= EPSILON)
		return(-1);
	if (t2 <= EPSILON)
	{
		*closest = --ptr;
		return (t1);
	}
	roots1 = (roots1.x > roots1.y) ? roots1.yx : roots1;
	roots2 = (roots2.x > roots2.y) ? roots2.yx : roots2;
	if (roots1.x < EPSILON)
		return (-1);
	if (roots2.y < roots1.x)
	{
		*closest = --ptr;
		return (roots1.x);
	}
	else if (roots1.x > roots2.x && roots2.y < roots1.y)
	{
		*closest = ptr;
		return (roots2.y);
	}
	else if (roots2.x < roots1.x && roots2.y > roots1.y)
		return (-1);
	else if (roots1.x < roots2.x && roots2.y < roots1.y)
	{
		*closest = --ptr;
		return (roots1.x);
	}
	*closest = --ptr;
	return (t1);
}

static float	bool_intersection_intersect(global t_object *ptr, t_ray ray, global t_object **closest)
{
	float2	roots1;
	float2	roots2;
	float 	t1;
	float 	t2;

	t1 = sphere_intersect1(&ptr->prim.sphere, ray, &roots1);
	ptr++;
	t2 = sphere_intersect1(&ptr->prim.sphere, ray, &roots2);
	if (t1 <= EPSILON || t2 <= EPSILON)
		return(-1);
	roots1 = (roots1.x > roots1.y) ? roots1.yx : roots1;
	roots2 = (roots2.x > roots2.y) ? roots2.yx : roots2;
	if (roots1.x < EPSILON && roots2.x < EPSILON)
		return (-1);
	if (roots1.x > EPSILON && roots1.x > roots2.x && roots1.x < roots2.y)
	{
		*closest = --ptr;
		return (roots1.x);
	}
	if (roots2.x > 0 && roots2.x > roots1.x && roots2.x < roots1.y)
	{
		*closest = ptr;
		return (roots2.x);
	}
	return (-1);
}


static float parabaloid_intersect(global t_parabaloid* obj, t_ray ray, float* t) {
	float2		roots;
	float3		x;
	float		params[3];
	float		m1;
	float		m2;

	obj->normal = normalize(obj->normal);
	x = ray.o;
	params[0] = dot(ray.d, ray.d) - dot(ray.d, obj->normal) * dot(ray.d, obj->normal);
	params[1] = 2 * (dot(x, ray.d) - dot(ray.d, obj->normal) * (dot(x, obj->normal) + 2 * obj->radius));
	params[2] = dot(x, x) - dot(x, obj->normal) * (dot(x, obj->normal) + 4 * obj->radius);
	ft_roots(&roots,params[0],params[1],params[2]);
	m1 = dot(ray.d, obj->normal) * roots[0] + dot(x, obj->normal);
	m2 = dot(ray.d, obj->normal) * roots[1] + dot(x, obj->normal);
	if ((roots[0] <= 0.0f && roots[1] <= 0.0f) || (roots[0] == roots[1]))
		return (INFINITY);
	if (obj->max > 0)
	{
		if (roots[0] > 0.0f && roots[1] < 0.0f && m1 > 0.0f && m1 < obj->max)
		{
			*t = roots[0];
			return (1);
		}
		else if (roots[1] > 0.0f && roots[0] < 0.0f && m2 > 0.0f && m2 < obj->max)
		{
			*t = roots[1];
			return (1);
		}
		else if (roots[0] > 0.0f && roots[1] > 0.0f)
		{
			if (roots[0] > 0.0f && m1 > 0.0f && m1 < obj->max)
			{
				*t = roots[0];
				return (1);
			}
			else if (roots[1] > 0.0f && m2 > 0.0f && m2 < obj->max)
			{
				*t = roots[1];
				return (1);
			}
		}
	}
	else if (roots[0] > 0 && roots[1] > 0)
	{
		*t = roots[0] < roots[1] ? roots[0] : roots[1];
		return (1);
	}
	else if (roots[0] > 0 && roots[1] < 0)
	{
		*t = roots[0];
		return (1);
	}
	else if (roots[1] > 0 && roots[0] < 0)
	{
		*t = roots[1];
		return (1);
	}
	return (INFINITY);
}


static void intersect(global t_object* obj,
						global t_object** closest,
						t_ray ray,
						float* m,
						float* closest_dist) {
	float dist;
	global t_object *closest_obj;
	float tmp_m = 0;
	switch (obj->type) {
		case sphere:
			dist = sphere_intersect(&obj->prim.sphere, ray);
			break;
		case plane:
			dist = plane_intersect(&obj->prim.plane, ray);
			break;
		case cylinder:
			dist = cylinder_intersect(&obj->prim.cylinder, ray, &tmp_m);
			break;
		case cone:
			dist = cone_intersect(&obj->prim.cone, ray, &tmp_m);
			break;
		case disk:
			dist = disk_intersect(&obj->prim.disk, ray);
			break;
		case torus:
			dist = torus_intersect(&obj->prim.torus, ray);
			break;
		case triangle:
			dist = triangle_intersect(&obj->prim.triangle, ray);
			break;
        case mobius:
            dist = mobius_intersect(&obj->prim.mobius, ray);
            break;
		case cube:
			dist = cube_intersect(&obj->prim.cube, ray, &tmp_m, &closest_obj);
			break;
		case bool_substraction:
			dist = bool_substraction_intersect(obj, ray,  &closest_obj);
			break;
		case bool_intersection:
			dist = bool_intersection_intersect(obj, ray,  &closest_obj);
			break;
		case parabaloid:
			dist = parabaloid_intersect(&obj->prim.parabaloid, ray,  &tmp_m);
			break;
		case julia:
			dist = intersect_julia(obj->prim.julia.c, ray);
			break;
		default:
			break;
	}
	if (dist <= EPSILON || dist > *closest_dist)
		return;
	*closest_dist = dist;
	if (obj->type == bool_substraction || obj->type == second || obj->type == bool_intersection || (obj->type == cube && closest_obj))
		*closest = closest_obj;
	else
		*closest = obj;
	*m = tmp_m;
}
