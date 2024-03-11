local Lerp = {}

function Lerp.lerp(a, b, t)
	return a + (b - a) * t
end

function Lerp.quad(p0: Vector3, p1: Vector3, p2: Vector3, t: number): Vector3
	return (1 - t)^2 * p0 + 2 * (1 - t) * t * p1 + t^2 * p2
end

function Lerp.cubic(p0, p1, p2, p3, t)
	return (1 - t)^3*p0 + 3*(1 - t)^2*t*p1 + 3*(1 - t)*t^2*p2 + t^3*p3
end

return Lerp
