interface Props {
  size?: number
  className?: string
}

export default function NeedLinkLogo({ size = 32, className = '' }: Props) {
  const id = 'nl-bg'
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 32 32"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      aria-hidden="true"
      className={className}
    >
      <defs>
        <radialGradient id={id} cx="42%" cy="38%" r="70%">
          <stop offset="0%"   stopColor="#1178A0" />
          <stop offset="100%" stopColor="#071D2C" />
        </radialGradient>
      </defs>
      <rect width="32" height="32" rx="7" fill={`url(#${id})`} />
      {/* soft glow */}
      <polyline
        points="6.5,6.2 6.5,25.8 16.3,6.2 16.3,25.8 25.5,25.8"
        stroke="white" strokeWidth="4" strokeLinecap="round" strokeLinejoin="round"
        fill="none" opacity="0.08"
      />
      {/* NL ligature */}
      <polyline
        points="6.5,6.2 6.5,25.8 16.3,6.2 16.3,25.8 25.5,25.8"
        stroke="white" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round"
        fill="none"
      />
      {/* accent dot */}
      <circle cx="25.5" cy="25.8" r="1.4" fill="#0AC8EC" opacity="0.9" />
    </svg>
  )
}
