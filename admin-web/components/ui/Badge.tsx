import { cn, getStatusColor } from '@/lib/utils';

interface BadgeProps {
  children: React.ReactNode;
  status?: string;
  className?: string;
}

export default function Badge({ children, status, className }: BadgeProps) {
  const statusClass = status ? getStatusColor(status) : '';
  
  return (
    <span className={cn(
      'inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium',
      statusClass,
      className
    )}>
      {children}
    </span>
  );
}